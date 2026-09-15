import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/sessions/session_type.dart';

/// Aggregated session-result metrics for a requested period.
class SessionStatistics {
  final int numberOfSessions;

  final List<int> numberOfSessionsBySessionType;

  int getNumberOfSessionsBySessionType(SessionType sessionType) {
    return numberOfSessionsBySessionType[sessionType.index];
  }

  final int numberOfAnswers;
  final int numberOfExercisesCompleted;

  final List<int> numberOfAnswersByStatus;

  int getNumberOfAnswersByStatus(ExerciseStatus status) {
    return numberOfAnswersByStatus[status.index];
  }

  final Duration totalTimeSpent;
  final int numberOfTimedSessions;
  final Duration averageTimePerSession;

  final double averageNumberOfAnswersPerSession;

  SessionStatistics({
    required this.numberOfSessions,
    required this.numberOfSessionsBySessionType,
    required this.numberOfAnswers,
    required this.numberOfExercisesCompleted,
    required this.numberOfAnswersByStatus,
    required this.totalTimeSpent,
    required this.numberOfTimedSessions,
    required this.averageTimePerSession,
    required this.averageNumberOfAnswersPerSession,
  });
}
