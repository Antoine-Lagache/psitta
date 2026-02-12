/// État d'un exercice dans une session d'apprentissage.
/// l'état n'est pas persisté, existe uniquement pendant la session.
enum ExerciseStatus {
  newExercise, //nouvel exercice
  toreview, // exercice à revoir
  learning, // nouvel exercice en cours d'apprentissage
  relearning, // exercice à réapprendre
  completed, // exercice terminé pour la session
}
