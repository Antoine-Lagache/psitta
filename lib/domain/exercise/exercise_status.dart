/// Transient state of an exercise within a learning session.
enum ExerciseStatus {
  newExercise(0), // Not answered before this session.
  toReview(1), // Due from an earlier session.
  learning(2), // New exercise repeating within this session.
  relearning(3), // Review exercise repeating after a failed answer.
  completed(4), // Finished for this session.
  consolidating(5); // Training without further SRS updates.

  const ExerciseStatus(this.code);

  /// The code is a stable way to persist the status in the database.
  /// The index of the enum may change if new statuses are added.
  final int code;

  static ExerciseStatus fromCode(int code) =>
      ExerciseStatus.values.firstWhere((e) => e.code == code);
}
