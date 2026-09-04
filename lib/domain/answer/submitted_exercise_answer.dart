part of 'exercise_answer.dart';

/// Represents an answer that must update exercise and scheduling state.
final class SubmittedExerciseAnswer extends ExerciseAnswer {
  @override
  final Grade grade;
  /// Time at which the user completed the exercise.
  final DateTime answeredAt;
  //final List<Duration> stepDurations; // TODO: Store step durations if needed.

  SubmittedExerciseAnswer({
    required this.grade,
    required this.answeredAt,
    //required List<Duration> stepDurations,
  }); //: stepDurations = List.unmodifiable(stepDurations);

  @override
  DateTime get at => answeredAt;

  //Duration get totalDuration => stepDurations.fold(Duration.zero, (a, b) => a + b);

  //DateTime get startedAt => answeredAt.subtract(totalDuration);
}
