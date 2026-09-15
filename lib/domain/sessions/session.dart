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

  Exercise get currentExercise =>
      _scheduler.currentExercise ?? (throw StateError('No current exercise'));

  int getCurrentContentId() => currentExercise.getContentId();

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
    if (_intermediateResult.startedAt != null) {
      throw StateError('Cannot start a session more than once');
    }
    _intermediateResult.startedAt = now;
    _scheduler.selectNextExercise(now);
  }

  /// Recalculates the next exercise when an unfinished session is restored.
  void resumeSession(DateTime now) {
    if (_intermediateResult.startedAt == null || _intermediateResult.endAt != null) {
      throw StateError('Only an unfinished session can be resumed');
    }
    if (now.isBefore(_intermediateResult.startedAt!)) {
      throw StateError('Cannot resume a session before it started');
    }

    _scheduler.selectNextExercise(now);
  }

  /// Returns the number of exercises currently in [status].
  int countExerciseByStatus(ExerciseStatus status) {
    return _scheduler.countExerciseByStatus(status);
  }

  List<Grade> getCurrentExerciseAllowedGrade() {
    if (_scheduler.currentExercise == null) {
      throw StateError('No current exercise');
    }

    return Grade.values.where(_scheduler.currentExercise!.isGradeAllowed).toList();
  }

  /// Applies [answer], updates aggregates, and selects the next exercise.
  void submitAnswer(SubmittedExerciseAnswer answer) {
    final exercise = _scheduler.currentExercise;
    if (exercise == null) {
      throw StateError('No current exercise');
    }

    if (isSessionFinished()) {
      throw Exception("Cannot submit answer for a finished session");
    }
    if (!exercise.isGradeAllowed(answer.grade)) {
      throw StateError('The grade is not allowed by this exercise');
    }
    _validateTimestamp(answer.answeredAt);

    final answeredStatus = exercise.status;
    exercise.applyAnswer(answer, config);

    _intermediateResult.numberOfAnswersByStatus[answeredStatus.index]++;

    if (exercise.status == ExerciseStatus.completed) {
      _intermediateResult.numberOfUniqueExercisesCompleted++;
    }

    _scheduler.selectNextExercise(answer.answeredAt);
  }

  /// Previews an answer interval without modifying the current exercise.
  Duration getPreviewInterval(PreviewExerciseAnswer answer) {
    if (_scheduler.currentExercise == null) {
      throw StateError('No current exercise');
    }

    if (isSessionFinished()) {
      throw Exception("Cannot preview interval for a finished session");
    }
    if (!_scheduler.currentExercise!.isGradeAllowed(answer.grade)) {
      throw StateError('The grade is not allowed by this exercise');
    }

    return _scheduler.currentExercise!.previewInterval(answer, config);
  }

  bool isSessionFinished() {
    return !_scheduler.hasNextExercise() || _intermediateResult.endAt != null;
  }

  /// Adds one measured active segment to the persisted session aggregate.
  void addTimeSpent(Duration duration) {
    if (_intermediateResult.startedAt == null || _intermediateResult.endAt != null) {
      throw StateError('Time can only be added to an active session');
    }
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'Must not be negative');
    }

    _intermediateResult.totalTimeSpent += duration;
  }

  /// Marks the session complete and returns its final aggregate result.
  SessionResult endSession(DateTime now) {
    if (_intermediateResult.startedAt == null) {
      throw StateError('Cannot end a session before it started');
    }
    if (_intermediateResult.endAt != null) {
      throw StateError('Session already ended');
    }

    _validateTimestamp(now);
    _intermediateResult.endAt = now;
    return _intermediateResult;
  }

  void _validateTimestamp(DateTime now) {
    final startedAt = _intermediateResult.startedAt;
    if (startedAt != null && now.isBefore(startedAt)) {
      throw StateError('Session timestamps must be chronological');
    }
  }
}
