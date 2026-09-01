import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/sessions/session_type.dart';

class SessionStatistics {
  final int numberOfSessions;

  final List<int> numberOfSessionsBySessionType;

  int getNumberOfSessionsBySessionType(SessionType sessionType) {
    return numberOfSessionsBySessionType[sessionType.index];
  }

  final int numberOfExercisesAnswered;
  final int numberOfExercisesCompleted;

  final List<int> numberOfExercisesByStatus;

  int getNumberOfExercisesByStatus(ExerciseStatus status) {
    return numberOfExercisesByStatus[status.index];
  }

  final Duration totalTimeSpent;
  final int numberOfTimedSessions;
  final Duration averageTimePerSession;

  final double averageNumberOfExercisesPerSession;

  SessionStatistics({
    required this.numberOfSessions,
    required this.numberOfSessionsBySessionType,
    required this.numberOfExercisesAnswered,
    required this.numberOfExercisesCompleted,
    required this.numberOfExercisesByStatus,
    required this.totalTimeSpent,
    required this.numberOfTimedSessions,
    required this.averageTimePerSession,
    required this.averageNumberOfExercisesPerSession,
  });
}
