part of 'exercise_answer.dart';

/// Represents a hypothetical answer used to preview its scheduling interval.
final class PreviewExerciseAnswer extends ExerciseAnswer {
  @override
  final Grade grade;
  @override
  final DateTime at;

  PreviewExerciseAnswer({required this.grade, required this.at});
}
