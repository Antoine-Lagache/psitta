import 'package:psitta/domain/exercise/exercise.dart';

/// Immutable record of one submitted answer and its pre-answer exercise status.
class ExerciseHistoryEntry {
  final int? id;
  final int exerciseId;

  final Grade grade;
  final DateTime answeredAt;

  /// Exercise status at the time the answer was submitted.
  final ExerciseStatus status;

  /// Identifies the answered sentence for sentence exercises.
  final int? sentenceInstanceId;

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
