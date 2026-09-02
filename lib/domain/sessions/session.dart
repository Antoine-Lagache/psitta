import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/domain/sessions/session_scheduler.dart';
import 'package:psitta/domain/sessions/session_type.dart';

export 'package:psitta/domain/sessions/session_result.dart';
export 'package:psitta/domain/sessions/session_type.dart';

/// Owns the lifecycle, scheduling, and aggregate result of an SRS session.
class Session {
  /// SRS configuration shared by every exercise in this session.
  final SRSConfig config;

  /// Mutable aggregate updated after each submitted answer.
  late SessionResult _intermediateResult;
  SessionResult get intermediateResult => _intermediateResult;

  final SessionScheduler _scheduler;

  int getCurrentContentId() => _scheduler.currentExercise!.getContentId();

  List<ExerciseResume> getResumeList() => _scheduler.getResumeList();

  Session({
    required List<Exercise> exercises,
    required SessionType sessionType,
    required this.config,
    SessionResult? existingSessionResult,
  }) : _scheduler = SessionScheduler(exercises) {
    _initSession(sessionType);

    if (existingSessionResult != null) {
      if (sessionType != existingSessionResult.sessionType) {
        throw StateError(
          "The given SessionType must match the SessionType of the given SessionResult",
        );
      }
      _intermediateResult = existingSessionResult;
    } else {
      _intermediateResult = SessionResult(sessionType: sessionType);
    }
  }

  void _initSession(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.wordSession:
        if (!_scheduler.exercises.every((a) => a is WordExercise)) {
          throw Exception("All exercises must be WordExercise for a word session");
        }
      case SessionType.sentenceSession:
        if (!_scheduler.exercises.every((a) => a is SentenceExercise)) {
          throw Exception(
            "All exercises must be SentenceExercise for a sentence session",
          );
        }
    }
  }

  /// Starts the session and selects its first exercise.
  void beginSession(DateTime now) {
    // TODO(review): Enforce lifecycle rules with runtime validation; assertions
    // are disabled in release builds and currently guard repeated starts.
    assert(_intermediateResult.startedAt == null);
    _intermediateResult.startedAt = now;
    _scheduler.selectNextExercise(now);
  }

  /// Returns the number of exercises currently in [status].
  int countExerciseByStatus(ExerciseStatus status) {
    return _scheduler.countExerciseByStatus(status);
  }

  List<Grade> getCurrentExerciseAllowedGrade() {
    assert(_scheduler.currentExercise != null);

    return Grade.values.where(_scheduler.currentExercise!.isGradeAllowed).toList();
  }

  /// Applies [answer], updates aggregates, and selects the next exercise.
  void submitAnswer(SubmittedExerciseAnswer answer) {
    assert(_scheduler.currentExercise != null);

    if (isSessionFinished()) {
      throw Exception("Cannot submit answer for a finished session");
    }

    _intermediateResult.numberOfExercicesByStatus[_scheduler
        .currentExercise!
        .status
        .code]++;

    _scheduler.currentExercise!.applyAnswer(answer, config);

    if (_scheduler.currentExercise!.status == ExerciseStatus.completed) {
      _intermediateResult.numberOfUniqueExercisesCompleted++;
    }

    _scheduler.selectNextExercise(answer.answeredAt);
  }

  /// Previews an answer interval without modifying the current exercise.
  Duration getPreviewInterval(PreviewExerciseAnswer answer) {
    assert(_scheduler.currentExercise != null);

    if (isSessionFinished()) {
      throw Exception("Cannot preview interval for a finished session");
    }

    return _scheduler.currentExercise!.previewInterval(answer, config);
  }

  bool isSessionFinished() {
    return !_scheduler.hasNextExercise() || _intermediateResult.endAt != null;
  }

  /// Marks the session complete and returns its final aggregate result.
  SessionResult endSession(DateTime now) {
    assert(_intermediateResult.endAt == null);
    _intermediateResult.endAt = now;
    return _intermediateResult;
  }
}
