part of 'exercise_answer.dart';

/// is used to get the preview of the interval
final class PreviewExerciseAnswer extends ExerciseAnswer {
  @override
  final Grade grade;
  @override
  final DateTime at;

  PreviewExerciseAnswer({required this.grade, required this.at});
}
