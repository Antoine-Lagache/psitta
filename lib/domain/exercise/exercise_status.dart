/// Status of an exercise in a learning session.
/// The status is not persisted, exists only during the session.
enum ExerciseStatus {
  newExercise(0), // new exercise
  toReview(1), // exercise to review
  learning(2), // new exercise being learned
  relearning(3), // exercise to relearn
  completed(4), // exercise completed for the session
  consolidating(5); // exercise being trained (SRS is not updated in that status)

  const ExerciseStatus(this.code);

  /// The code is a stable way to persist the status in the database.
  /// The index of the enum may change if new statuses are added.
  final int code;

  static ExerciseStatus fromCode(int code) =>
      ExerciseStatus.values.firstWhere((e) => e.code == code);
}
