import 'package:psitta/domain/exercise/exercise.dart';

class ExerciseHistoryEntry {
  final int? id;
  final int exerciseId;

  final Grade grade;
  final DateTime answeredAt;

  // The status of the exercise at the time of the answer
  final ExerciseStatus status;

  final int? sentenceInstanceId; // optional, only for sentence exercises

  ExerciseHistoryEntry({
    this.id,
    required this.exerciseId,
    required this.grade,
    required this.answeredAt,
    required this.status,
    this.sentenceInstanceId,
  });

  factory ExerciseHistoryEntry.fromAnswer({
    required SubmittedExerciseAnswer answer,
    required int exerciseId,
    required ExerciseStatus status,
    int? sentenceInstanceId,
  }) {
    return ExerciseHistoryEntry(
      exerciseId: exerciseId,
      grade: answer.grade,
      answeredAt: answer.answeredAt,
      status: status,
      sentenceInstanceId: sentenceInstanceId,
    );
  }
}
