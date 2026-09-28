import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/session/start_session_result.dart';
import 'package:psitta/application/models/session/submit_answer_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/presentation/load_error_content.dart';
import 'package:psitta/ui/screens/learning/learning_content.dart';

enum _LearningStatus {
  loading,
  exercise,
  completed,
  ended,
  unavailable,
  failure,
}

/// Runs one learning session and presents its current exercise.
class LearningScreen extends StatefulWidget {
  final SessionController sessionController;
  final ContentRenderer contentRenderer;
  final SessionType sessionType;
  final bool resumeSession;

  const LearningScreen({
    required this.sessionController,
    required this.contentRenderer,
    required this.sessionType,
    required this.resumeSession,
    super.key,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  _LearningStatus _status = _LearningStatus.loading;
  Widget? _front;
  Widget? _back;
  Object? _error;
  String _unavailableMessage = 'This session is no longer available.';
  List<Grade> _allowedGrades = const [];
  Map<Grade, Duration> _previewIntervals = const {};
  bool _showingAnswer = false;

  // The answer is persisted by the next, pause, or end action once confirmed.
  Grade? _selectedGrade;
  bool _operationInProgress = true;
  bool _exitConfirmationOpen = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeSession());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _canPop,
      onPopInvokedWithResult: _handlePopAttempt,
      child: Scaffold(appBar: _buildAppBar(), body: _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: _operationInProgress ? null : _requestExit,
        tooltip: 'Pause session',
        icon: const Icon(Icons.close),
      ),
      title: Text(_sessionTitle),
      actions: [
        IconButton(
          onPressed: _canEndSession ? _requestEndSession : null,
          tooltip: 'End session',
          icon: const Icon(Icons.stop_circle_outlined),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return switch (_status) {
      _LearningStatus.loading => const Center(child: CircularProgressIndicator()),
      _LearningStatus.exercise => _buildExercise(),
      _LearningStatus.completed => _buildMessage(
        icon: Icons.check_circle_outline,
        title: 'Session completed',
        message: 'Your progress has been saved.',
      ),
      _LearningStatus.ended => _buildMessage(
        icon: Icons.stop_circle_outlined,
        title: 'Session ended',
        message: 'Your completed answers have been saved.',
      ),
      _LearningStatus.unavailable => _buildMessage(
        icon: Icons.inbox_outlined,
        title: 'Session unavailable',
        message: _unavailableMessage,
      ),
      _LearningStatus.failure => LoadErrorContent(
        message: 'An error interrupted the learning session.',
        error: _error!,
        onRetry: _retry,
      ),
    };
  }

  Widget _buildExercise() {
    return LearningContent(
      front: _front!,
      back: _back!,
      showingAnswer: _showingAnswer,
      interactionEnabled: !_operationInProgress,
      selectedGrade: _selectedGrade,
      allowedGrades: _allowedGrades,
      previewIntervals: _previewIntervals,
      onRevealAnswer: _revealAnswer,
      onGradeSelected: _selectGrade,
      onToggleSide: _toggleSide,
      onCancelAnswer: _cancelAnswer,
      onNextExercise: _confirmAnswerAndContinue,
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: _returnHome, child: const Text('Return home')),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeSession() async {
    try {
      final sessionAvailable = await _openSession();
      if (!sessionAvailable) {
        return;
      }
      await _loadCurrentExercise();
    } on Object catch (error, stackTrace) {
      _showFailure(error, stackTrace);
    }
  }

  Future<bool> _openSession() async {
    if (widget.resumeSession) {
      final resumed = await widget.sessionController.resumeActiveSession(
        widget.sessionType,
      );
      if (!resumed) {
        _showUnavailable('The saved session could not be found.');
      }
      return resumed;
    }

    final result = await widget.sessionController.startNewSession(widget.sessionType);
    switch (result) {
      case StartSessionResult.started:
        return true;
      case StartSessionResult.noExerciseAvailable:
        _showUnavailable('No exercise is currently available.');
        return false;
      case StartSessionResult.activeSessionAlreadyExists:
        return _resumeExistingSession();
    }
  }

  Future<bool> _resumeExistingSession() async {
    final resumed = await widget.sessionController.resumeActiveSession(
      widget.sessionType,
    );
    if (!resumed) {
      _showUnavailable('The saved session could not be found.');
    }
    return resumed;
  }

  Future<void> _loadCurrentExercise() async {
    _setLoading();
    final content = await widget.sessionController.getCurrentExerciseContent();
    final front = await widget.contentRenderer.render(content, FieldSide.front);
    final back = await widget.contentRenderer.render(content, FieldSide.back);
    final grades = widget.sessionController.getCurrentExerciseAllowedGrade();
    final intervals = widget.sessionController.getCurrentExercisePreviewIntervals();

    if (!mounted) {
      return;
    }
    setState(() {
      _front = front;
      _back = back;
      _allowedGrades = grades;
      _previewIntervals = intervals;
      _showingAnswer = false;
      _selectedGrade = null;
      _operationInProgress = false;
      _status = _LearningStatus.exercise;
    });
  }

  void _revealAnswer() {
    setState(() {
      _showingAnswer = true;
    });
  }

  void _selectGrade(Grade grade) {
    setState(() {
      _selectedGrade = grade;
    });
  }

  void _toggleSide() {
    setState(() {
      _showingAnswer = !_showingAnswer;
    });
  }

  void _cancelAnswer() {
    setState(() {
      _selectedGrade = null;
      _showingAnswer = true;
    });
  }

  Future<void> _confirmAnswerAndContinue() async {
    if (_operationInProgress || _selectedGrade == null) {
      return;
    }
    setState(() {
      _operationInProgress = true;
    });

    try {
      final result = await _submitPendingAnswer();
      if (result == SubmitAnswerResult.sessionCompleted) {
        _showCompleted();
        return;
      }
      await _loadCurrentExercise();
    } on Object catch (error, stackTrace) {
      _showFailure(error, stackTrace);
    }
  }

  Future<void> _requestEndSession() async {
    if (!_canEndSession || _exitConfirmationOpen) {
      return;
    }

    _exitConfirmationOpen = true;
    bool? confirmed;
    try {
      confirmed = await _confirmEndSession();
    } finally {
      _exitConfirmationOpen = false;
    }
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _operationInProgress = true;
    });
    try {
      final result = await _submitPendingAnswer();
      if (result == SubmitAnswerResult.sessionCompleted) {
        _showCompleted();
        return;
      }
      await widget.sessionController.endSession();
      _showEnded();
    } on Object catch (error, stackTrace) {
      _showFailure(error, stackTrace);
    }
  }

  Future<void> _retry() async {
    if (_operationInProgress) {
      return;
    }
    _setLoading();

    try {
      if (!widget.sessionController.hasActiveSession) {
        final resumed = await widget.sessionController.resumeActiveSession(
          widget.sessionType,
        );
        if (!resumed) {
          _showUnavailable('The saved session could not be found.');
          return;
        }
      }
      await _loadCurrentExercise();
    } on Object catch (error, stackTrace) {
      _showFailure(error, stackTrace);
    }
  }

  void _handlePopAttempt(bool didPop, bool? result) {
    if (!didPop) {
      unawaited(_requestExit());
    }
  }

  Future<void> _requestExit() async {
    if (_operationInProgress || _exitConfirmationOpen) {
      return;
    }
    if (!widget.sessionController.hasActiveSession) {
      _returnHome();
      return;
    }

    _exitConfirmationOpen = true;
    bool? confirmed;
    try {
      confirmed = await _confirmPause();
    } finally {
      _exitConfirmationOpen = false;
    }
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _operationInProgress = true;
    });
    try {
      final result = await _submitPendingAnswer();
      if (result == SubmitAnswerResult.sessionCompleted) {
        _returnHome();
        return;
      }
      await widget.sessionController.pauseSession();
      _returnHome();
    } on Object catch (error, stackTrace) {
      _showFailure(error, stackTrace);
    }
  }

  Future<bool?> _confirmPause() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause this session?'),
        content: Text(_pauseConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pause session'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmEndSession() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this session?'),
        content: Text(_endConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
  }

  void _showCompleted() {
    if (!mounted) {
      return;
    }
    setState(() {
      _operationInProgress = false;
      _status = _LearningStatus.completed;
    });
  }

  Future<SubmitAnswerResult?> _submitPendingAnswer() {
    final grade = _selectedGrade;
    if (grade == null) {
      return Future<SubmitAnswerResult?>.value();
    }
    return widget.sessionController.submitAnswer(grade);
  }

  void _showEnded() {
    if (!mounted) {
      return;
    }
    setState(() {
      _operationInProgress = false;
      _selectedGrade = null;
      _status = _LearningStatus.ended;
    });
  }

  void _showUnavailable(String message) {
    if (mounted) {
      setState(() {
        _unavailableMessage = message;
        _operationInProgress = false;
        _status = _LearningStatus.unavailable;
      });
    }
  }

  void _showFailure(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Psitta learning screen',
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _error = error;
      _operationInProgress = false;
      _status = _LearningStatus.failure;
    });
  }

  void _setLoading() {
    if (!mounted) {
      return;
    }
    setState(() {
      _operationInProgress = true;
      _status = _LearningStatus.loading;
    });
  }

  void _returnHome() {
    if (!mounted || _canPop) {
      return;
    }
    setState(() {
      _canPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  String get _sessionTitle {
    return switch (widget.sessionType) {
      SessionType.wordSession => 'Words',
      SessionType.sentenceSession => 'Sentences',
    };
  }

  bool get _canEndSession {
    return !_operationInProgress && widget.sessionController.hasActiveSession;
  }

  String get _pauseConfirmationMessage {
    if (_selectedGrade != null) {
      return 'The selected answer will be saved before pausing. '
          'You can resume this session later.';
    }
    return 'Your confirmed answers are saved. You can resume this session later.';
  }

  String get _endConfirmationMessage {
    if (_selectedGrade != null) {
      return 'The selected answer will be saved. All remaining exercises '
          'will be left unfinished.';
    }
    return 'Confirmed answers are saved. The current exercise and all '
        'remaining exercises will be left unfinished.';
  }
}
