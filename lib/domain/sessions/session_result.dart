import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/sessions/session_type.dart';

export 'package:psitta/domain/exercise/exercise_status.dart';

/// Mutable aggregate owned by [Session] and persisted as the session result.
class SessionResult {
  int? id;

  SessionType sessionType;

  List<int> numberOfAnswersByStatus;
  int getNumberOfAnswersByStatus(ExerciseStatus status) {
    return numberOfAnswersByStatus[status.index];
  }

  int numberOfUniqueExercisesCompleted;

  DateTime? startedAt;
  DateTime? endAt;
  Duration totalTimeSpent;

  SessionResult({this.id, required this.sessionType, this.totalTimeSpent = Duration.zero})
    : numberOfAnswersByStatus = List<int>.filled(ExerciseStatus.values.length, 0),
      numberOfUniqueExercisesCompleted = 0,
      endAt = null {
    if (totalTimeSpent.isNegative) {
      throw ArgumentError.value(totalTimeSpent, 'totalTimeSpent', 'Must not be negative');
    }
  }
}
