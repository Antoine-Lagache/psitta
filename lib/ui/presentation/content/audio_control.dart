import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Displays playback controls for one local or remote audio resource.
class AudioControl extends StatefulWidget {
  final Uri source;

  const AudioControl({required this.source, super.key});

  @override
  State<AudioControl> createState() => _AudioControlState();
}

class _AudioControlState extends State<AudioControl> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerState? _playerState;
  Object? _error;

  bool get _isLoading {
    final state = _playerState?.processingState;
    return state == ProcessingState.loading || state == ProcessingState.buffering;
  }

  bool get _isPlaying => _playerState?.playing ?? false;

  bool get _isCompleted => _playerState?.processingState == ProcessingState.completed;

  @override
  void initState() {
    super.initState();
    _listenToPlayer();
    unawaited(_loadAudio());
  }

  void _listenToPlayer() {
    _subscriptions.addAll([
      _player.positionStream.listen((position) => _updatePosition(position)),
      _player.durationStream.listen((duration) => _updateDuration(duration)),
      _player.playerStateStream.listen((state) => _updatePlayerState(state)),
    ]);
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setAudioSource(AudioSource.uri(widget.source));
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        return;
      }
      if (_isCompleted) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _seek(double milliseconds) async {
    try {
      await _player.seek(Duration(milliseconds: milliseconds.round()));
    } on Object catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (mounted) {
      setState(() => _error = error);
    }
  }

  void _updatePosition(Duration position) {
    if (mounted) {
      setState(() => _position = position);
    }
  }

  void _updateDuration(Duration? duration) {
    if (mounted) {
      setState(() => _duration = duration ?? Duration.zero);
    }
  }

  void _updatePlayerState(PlayerState state) {
    if (mounted) {
      setState(() => _playerState = state);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
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
      onPressed: _playerState == null ? null : _togglePlayback,
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
