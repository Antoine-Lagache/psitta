import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/sessions/session_type.dart';

export 'package:psitta/domain/exercise/exercise_status.dart';

/// Mutable aggregate owned by [Session] and persisted as the session result.
class SessionResult {
  int? id;

  SessionType sessionType;

  List<int> numberOfExercicesByStatus;
  int getNumberOfExercisesByStatus(ExerciseStatus status) {
    return numberOfExercicesByStatus[status.index];
  }

  int numberOfUniqueExercisesCompleted;

  DateTime? startedAt;
  DateTime? endAt;
  Duration? get totalTimeSpent =>
      (startedAt == null) ? null : endAt?.difference(startedAt!);

  SessionResult({this.id, required this.sessionType})
    : numberOfExercicesByStatus = List<int>.filled(ExerciseStatus.values.length, 0),
      numberOfUniqueExercisesCompleted = 0,
      endAt = null;
}
