import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Displays playback controls for one local or remote audio resource.
class AudioControl extends StatefulWidget {
  final Uri source;

  const AudioControl({required this.source, super.key});

  @override
  State<AudioControl> createState() => _AudioControlState();
}

class _AudioControlState extends State<AudioControl> {
  static Future<void>? _engineInitialization;

  final SoLoud _engine = SoLoud.instance;

  AudioSource? _audioSource;
  SoundHandle? _soundHandle;
  StreamSubscription<StreamSoundEvent>? _soundEventsSubscription;
  Timer? _positionTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;
  bool _isPlaying = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAudio());
  }

  Future<void> _loadAudio() async {
    try {
      await _ensureEngineInitialized();
      final source = await _loadSource();
      final handle = await _engine.play(source, paused: true);
      if (!mounted) {
        await _engine.stop(handle);
        await _engine.disposeSource(source);
        return;
      }
      _listenToSource(source);
      _updateLoadedState(source, handle);
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _ensureEngineInitialized() async {
    if (_engine.isInitialized) return;

    final initialization = _engineInitialization ??= _engine.init();
    try {
      await initialization;
    } on Object {
      _engineInitialization = null;
      rethrow;
    }
  }

  Future<AudioSource> _loadSource() {
    if (widget.source.scheme == 'file') {
      return _engine.loadFile(widget.source.toFilePath());
    }
    return _engine.loadUrl(widget.source.toString());
  }

  void _listenToSource(AudioSource source) {
    _soundEventsSubscription = source.soundEvents.listen((event) {
      if (event.handle == _soundHandle &&
          event.event == SoundEventType.handleIsNoMoreValid) {
        _handlePlaybackCompleted();
      }
    });
  }

  void _updateLoadedState(AudioSource source, SoundHandle handle) {
    setState(() {
      _audioSource = source;
      _soundHandle = handle;
      _duration = _engine.getLength(source);
      _isLoading = false;
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        _pause();
      } else {
        await _play();
      }
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _play() async {
    final source = _audioSource;
    if (source == null) return;

    var handle = _soundHandle;
    if (handle == null || !_engine.getIsValidVoiceHandle(handle)) {
      handle = await _engine.play(source, paused: true);
      _soundHandle = handle;
      _position = Duration.zero;
    }
    _engine.setPause(handle, false);
    _startPositionUpdates();
    setState(() => _isPlaying = true);
  }

  void _pause() {
    final handle = _soundHandle;
    if (handle == null) return;
    _engine.setPause(handle, true);
    _positionTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _startPositionUpdates() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refreshPosition(),
    );
  }

  void _refreshPosition() {
    final handle = _soundHandle;
    if (!mounted || handle == null) return;
    if (!_engine.getIsValidVoiceHandle(handle)) return;
    setState(() => _position = _engine.getPosition(handle));
  }

  void _handlePlaybackCompleted() {
    _positionTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _position = _duration;
      _isPlaying = false;
      _soundHandle = null;
    });
  }

  void _seek(double milliseconds) {
    try {
      final handle = _soundHandle;
      if (handle == null) return;
      final position = Duration(milliseconds: milliseconds.round());
      _engine.seek(handle, position);
      setState(() => _position = position);
    } on Object catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = error;
      _isLoading = false;
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    unawaited(_soundEventsSubscription?.cancel());
    unawaited(_releaseAudio());
    super.dispose();
  }

  Future<void> _releaseAudio() async {
    final handle = _soundHandle;
    final source = _audioSource;
    if (!_engine.isInitialized) return;
    if (handle != null && _engine.getIsValidVoiceHandle(handle)) {
      await _engine.stop(handle);
    }
    if (source != null) {
      await _engine.disposeSource(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return SelectableText('Unable to play audio: $error');
    }

    return Semantics(
      label: 'Audio player',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayButton(),
          const SizedBox(width: 4),
          _buildProgressSlider(),
          const SizedBox(width: 4),
          Text('${_formatTime(_position)} / ${_formatTime(_duration)}'),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    final totalMilliseconds = _duration.inMilliseconds;
    final positionMilliseconds = _position.inMilliseconds.clamp(0, totalMilliseconds);

    return SizedBox(
      width: 160,
      child: Slider(
        value: positionMilliseconds.toDouble(),
        max: totalMilliseconds == 0 ? 1 : totalMilliseconds.toDouble(),
        onChanged: totalMilliseconds == 0 ? null : _seek,
      ),
    );
  }

  Widget _buildPlayButton() {
    if (_isLoading) {
      return const SizedBox.square(
        dimension: 48,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton.outlined(
      onPressed: _audioSource == null ? null : _togglePlayback,
      tooltip: _isPlaying ? 'Pause audio' : 'Play audio',
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
