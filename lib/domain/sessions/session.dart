import 'package:psitta/domain/exercises/exercice/sentence_exercise.dart';
import 'package:psitta/domain/exercises/exercice/word_exercise.dart';
import 'package:psitta/domain/exercises/exercise_scheduler.dart';
import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';

export 'package:psitta/domain/sessions/session_result.dart';
export 'package:psitta/domain/sessions/session_type.dart';

/// Class representing a session of exercises with SRS.
class Session {
  DateTime? _startedAt;
  DateTime? get startedAt => _startedAt;

  /// Config for the SRS algorithm used in this session
  final SRSConfig config;

  /// Intermediate result of the session
  /// modified on each answer submission
  /// returned by endSession or endSessionEarly
  SessionResult? _intermediateResult;

  final ExerciseScheduler _scheduler;
  ExercisePrompt? get currentPrompt => _scheduler.nextExercise?.getPrompt();

  Session(List<Exercise> exercises, SessionType sessionType, {required this.config})
    : _scheduler = ExerciseScheduler(exercises) {
    _initSession(sessionType);
  }

  void _initSession(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.wordSession:
        if (!_scheduler.exercises.every((a) => a is WordExercise)) {
          throw Exception("All exercises must be WordExercise for a word session");
        }
      case SessionType.sentenceSession:
        if (!_scheduler.exercises.every((a) => a is SentenceExercise)) {
          throw Exception("All exercises must be SentenceExercise for a sentence session");
        }
    }

    _intermediateResult = SessionResult(sessionType: sessionType);
  }

  /// Starts the session at the given date and time.
  /// Does nothing if the session has already started
  void beginSession(DateTime now) {
    assert(_startedAt == null);
    _startedAt ??= now;
    _intermediateResult!.startedAt = now;
    _scheduler.selectNextExercise(now);
  }

  /// returns the number of exercises to do or redo in the session
  int countExerciseByStatus(ExerciseStatus status) {
    return _scheduler.countExerciseByStatus(status);
  }

  SessionResult getSessionResult() {
    assert(_intermediateResult != null);
    return _intermediateResult!;
  }

  /// submits the answer for the current exercise with the given grade, then moves to the next exercise
  void submitAnswer(SubmittedExerciseAnswer answer, DateTime now) {
    assert(_scheduler.nextExercise != null);
    assert(_intermediateResult != null);

    if (isSessionFinished()) {
      throw Exception("Cannot submit answer for a finished session");
    }

    _intermediateResult!.numberOfExercicesByStatus[_scheduler.nextExercise!.status.index]++;

    _scheduler.nextExercise!.applyAnswer(answer, config);

    if (_scheduler.nextExercise!.status == ExerciseStatus.completed) {
      _intermediateResult!.numberOfUniqueExercisesCompleted++;
    }

    _scheduler.selectNextExercise(now);
    // update the intermediate result
  }

  /// returns the preview interval for the current exercise and a given grade
  Duration getPreviewInterval(PreviewExerciseAnswer answer) {
    assert(_scheduler.nextExercise != null);
    assert(_intermediateResult != null);

    if (isSessionFinished()) {
      throw Exception("Cannot preview interval for a finished session");
    }

    return _scheduler.nextExercise!.previewInterval(answer, config);
  }

  bool isSessionFinished() {
    return !_scheduler.hasNextExercise() || _intermediateResult?.endAt != null;
  }

  /// ends the session and returns the result
  /// a finished session can no longer receive answers and must be deleted
  SessionResult endSession(DateTime now) {
    assert(_intermediateResult != null);
    assert(_intermediateResult!.endAt == null);
    _intermediateResult!.endAt = now;
    return _intermediateResult!;
  }
}
