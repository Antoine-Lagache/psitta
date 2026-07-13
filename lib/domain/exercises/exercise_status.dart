/// Status of an exercise in a learning session.
/// The status is not persisted, exists only during the session.
enum ExerciseStatus {
  newExercise, // new exercise
  toreview, // exercise to review
  learning, // new exercise being learned
  relearning, // exercise to relearn
  completed, // exercise completed for the session
}
