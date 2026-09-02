import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/srs/grade.dart';

/// Aggregated answer-history metrics for a requested period.
class ExerciseStatistics {
  final int totalNumberAnswers;

  final List<int> numberOfAnswersByGrade;

  int getNumberOfAnswersByGrade(Grade grade) {
    return numberOfAnswersByGrade[grade.index];
  }

  final List<int> numberOfAnswersByStatus;

  int getNumberOfAnswersByStatus(ExerciseStatus status) {
    return numberOfAnswersByStatus[status.index];
  }

  final int numberOfDistinctExercisesAnswered;

  ExerciseStatistics({
    required this.totalNumberAnswers,
    required this.numberOfAnswersByGrade,
    required this.numberOfAnswersByStatus,
    required this.numberOfDistinctExercisesAnswered,
  });
}
