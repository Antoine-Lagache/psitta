/// Class representing the result of an exercise session.
/// This result is modified each time an exercise is answered.
/// It is modified only by the Session class.
class SessionResult {
  // Placeholder for SessionResult properties and methods
  int numberOfAnsweredExercices;
  int numberOfCorrectAnswers;
  int numberOfIncorrectAnswers;
  Duration totalTimeSpent;

  int numberOfNewExercices;
  int numberOfRevisedExercices;

  DateTime startedAt; //totalTimeSpent != startAt-endAt (if pause or quit session early) ???
  DateTime? endAt;

  SessionResult({
    required this.numberOfAnsweredExercices,
    required this.numberOfCorrectAnswers,
    required this.numberOfIncorrectAnswers,
    required this.totalTimeSpent,
    required this.numberOfNewExercices,
    required this.numberOfRevisedExercices,
    required this.startedAt,
    required this.endAt,
  });
}
