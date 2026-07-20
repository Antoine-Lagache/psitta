import 'package:psitta/domain/exercises/exercise_status.dart';

export 'package:psitta/domain/exercises/exercise_status.dart';

/// Class representing the result of an exercise session.
/// This result is modified each time an exercise is answered.
/// It is modified only by the Session class.
class SessionResult {
  List<int> numberOfExercicesByStatus;
  int numberOfUniqueExercisesCompleted;

  DateTime startedAt;
  DateTime? endAt;
  Duration? get totalTimeSpent => endAt?.difference(startedAt);

  SessionResult({required this.startedAt})
    : numberOfExercicesByStatus = List<int>.filled(ExerciseStatus.values.length, 0),
      numberOfUniqueExercisesCompleted = 0,
      endAt = null;
}
