
/// Classe représentant le résultat d'une session d'exercices.
/// Ce résultat est modifié à chaque fois qu'un exercice est répondu.
/// Il est modifé uniquement par la classe Session.
class SessionResult {
  // Placeholder for SessionResult properties and methods
  // SessionResult is modified each time an Exercices is Answered. 
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
    required this.endAt
  });

  
}