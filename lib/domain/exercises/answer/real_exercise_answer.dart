part of 'exercise_answer.dart';

// is the real answer
final class RealExerciseAnswer extends ExerciseAnswer {
  @override
  final Grade grade;
  final DateTime answeredAt; // time when the Exercise was ended
  final List<Duration> stepDurations;

  RealExerciseAnswer({
    required this.grade,
    required this.answeredAt,
    required List<Duration> stepDurations,
  }) : stepDurations = List.unmodifiable(stepDurations);

  @override
  DateTime get at => answeredAt;

  Duration get totalDuration => stepDurations.fold(Duration.zero, (a, b) => a + b);

  DateTime get startedAt => answeredAt.subtract(totalDuration);
}
