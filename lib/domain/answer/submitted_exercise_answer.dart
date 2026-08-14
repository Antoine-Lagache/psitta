part of 'exercise_answer.dart';

// is the submitted answer
final class SubmittedExerciseAnswer extends ExerciseAnswer {
  @override
  final Grade grade;
  final DateTime answeredAt; // time when the Exercise was ended
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
