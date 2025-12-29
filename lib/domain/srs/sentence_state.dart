import 'grade.dart';

/// État spécifique pour les exercices de phrases
/// utile pour pouvoir choisir une phrase parmi le groupe de phrase (cf SentenceExercice._getSentence())
class SentenceState {
  int shownCount; // shownCount >= successCount
  int successCount;

  SentenceState({required this.shownCount, required this.successCount});

  /// Met à jour l'état de la phrase en fonction de la note donnée
  /// appelé cette fonction une seule fois dans submitAnswer de Exercice
  void updateState(Grade grade) {
    shownCount += 1;
    if (gradeToInt(grade) >= 3) {
      successCount += 1;
    }
  }

  /// Calcule le score de la phrase en pourcentage de bonnes réponses
  /// utilisé pour comparer les phrases d'un SentenceExercice et choisir la phrase à afficher
  double getscore(){ //TODO: choisir un calcul plus pertinent ?
    if (shownCount == 0) {
      return 0.0;
    }
    return successCount / shownCount;
  }
}