import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/controllers/content_controller.dart';
import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';

import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';

/// Coordinates the application use cases for starting and running a session.
class SessionController {
  Session? _activeSession;
  Session? get activeSession => _activeSession;

  final SessionRepository _sessionRepository;
  final ExerciseRepository _exerciseRepository;
  final ContentController _contentController;

  final SRSConfig config = SRSConfig();

  SessionController({
    required SessionRepository sessionRepository,
    required ExerciseRepository exerciseRepository,
    required ContentController contentController,
  }) : _sessionRepository = sessionRepository,
       _exerciseRepository = exerciseRepository,
       _contentController = contentController;

  /// Creates, starts, and persists a session from due and new exercises.
  Future<void> startNewSession(SessionType sessionType) async {
    if (_activeSession != null) {
      throw StateError("A session is already active");
    }

    final String? exerciseType;
    switch (sessionType) {
      case SessionType.wordSession:
        exerciseType = 'word';
        break;
      case SessionType.sentenceSession:
        exerciseType = 'sentence';
    }

    final dueExercise = await _exerciseRepository.getDueExercises(
      DateTime.now(),
      config.reviewCount,
      exerciseType,
    );
    final newExercise = await _exerciseRepository.getNewExercises(
      config.newCount,
      exerciseType,
    );

    _activeSession = Session(
      exercises: dueExercise + newExercise,
      sessionType: sessionType,
      config: config,
    );

    _activeSession!.beginSession(DateTime.now());
    final id = await _sessionRepository.save(_activeSession!);
    _activeSession!.intermediateResult.id = id;

    if (isSessionFinished()) {
      await endSession();
    }
  }

  /// Restores the first persisted session of [sessionType], if one exists.
  Future<bool> resumeActiveSession(SessionType sessionType) async {
    if (_activeSession != null) {
      throw StateError("A session is already active");
    }

    final sessionResultList = await _sessionRepository.getAllActiveSessionResult();

    for (final sessionResult in sessionResultList) {
      if (sessionResult.sessionType == sessionType) {
        final session = await _sessionRepository.getActiveSession(sessionResult, config);
        session.resumeSession(DateTime.now());
        _activeSession = session;
        return true;
      }
    }

    return false;
  }

  /// Returns the number of unfinished sessions matching [sessionType].
  Future<int> numberActiveSession(SessionType sessionType) async {
    final sessionResultList = await _sessionRepository.getAllActiveSessionResult();

    int res = 0;
    for (final sessionResult in sessionResultList) {
      if (sessionResult.sessionType == sessionType) {
        res++;
      }
    }

    return res;
  }

  /// Loads the content selected by the active session.
  Future<Content> getCurrentExerciseContent() async {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }
    final contentId = activeSession!.getCurrentContentId();

    final content = await _contentController.getContentById(contentId);
    if (content == null) {
      throw StateError('Missing content with id $contentId');
    }
    return content;
  }

  List<Grade> getCurrentExerciseAllowedGrade() {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }

    return activeSession!.getCurrentExerciseAllowedGrade();
  }

  /// Applies [grade] and persists the resulting session-level progress.
  Future<void> submitAnswer(Grade grade) async {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }
    if (!(activeSession!.getCurrentExerciseAllowedGrade().contains(grade))) {
      throw StateError("This Grade is not allowed by the exercise");
    }

    final answeredExercise = activeSession!.currentExercise;
    activeSession!.submitAnswer(
      SubmittedExerciseAnswer(grade: grade, answeredAt: DateTime.now()),
    );
    await _exerciseRepository.save(answeredExercise);

    if (isSessionFinished()) {
      await endSession();
    } else {
      await _sessionRepository.update(activeSession!);
    }
  }

  Duration getPreviewInterval(Grade grade) {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }
    if (!(activeSession!.getCurrentExerciseAllowedGrade().contains(grade))) {
      throw StateError("This Grade is not allowed by the exercise");
    }

    return activeSession!.getPreviewInterval(
      PreviewExerciseAnswer(grade: grade, at: DateTime.now()),
    );
  }

  bool isSessionFinished() {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }
    return activeSession!.isSessionFinished();
  }

  Future<void> endSession() async {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }

    activeSession!.endSession(DateTime.now());

    await _sessionRepository.completeSession(activeSession!);
    _activeSession = null;
  }

  Future<void> pauseSession() async {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }

    await _sessionRepository.update(activeSession!);

    _activeSession = null;
  }
}
