import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';

class SessionController {
  Session? _activeSession;
  Session? get activeSession => _activeSession;

  final SessionRepository _sessionRepository;
  final ExerciseRepository _exerciseRepository;
  final ContentRepository _contentRepository;

  final SRSConfig config = SRSConfig();

  SessionController({required sqlite.SqliteDatabase database})
    : _sessionRepository = SessionRepository(database),
      _exerciseRepository = ExerciseRepository(database),
      _contentRepository = ContentRepository(database);

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
  }

  // return true if success, false if no active session was found
  Future<bool> resumeActiveSession(SessionType sessionType) async {
    if (_activeSession != null) {
      throw StateError("A session is already active");
    }

    final sessionResultList = await _sessionRepository.getAllActiveSessionResult();

    for (final sessionResult in sessionResultList) {
      if (sessionResult.sessionType == sessionType) {
        _activeSession = await _sessionRepository.getActiveSession(sessionResult, config);
        return true;
      }
    }

    return false;
  }

  // Returns the number of active sessions for the given session type.
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

  Future<Content> getCurrentExerciseContent() async {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }
    final contentId = activeSession!.getCurrentContentId();

    final content = await _contentRepository.getById(contentId);
    return content!;
  }

  List<Grade> getCurrentExerciseAllowedGrade() {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }

    return activeSession!.getCurrentExerciseAllowedGrade();
  }

  Future<void> submitAnswer(Grade grade) async {
    if (activeSession == null) {
      throw StateError("A session must be active first");
    }
    if (!(activeSession!.getCurrentExerciseAllowedGrade().contains(grade))) {
      throw StateError("This Grade is not allowed by the exercise");
    }

    activeSession!.submitAnswer(
      SubmittedExerciseAnswer(grade: grade, answeredAt: DateTime.now()),
    );

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
