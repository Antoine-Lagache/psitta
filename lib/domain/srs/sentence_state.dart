import 'grade.dart';

/// État spécifique pour les exercices de phrases
/// utile pour pouvoir choisir une phrase parmi le groupe de phrase (cf SentenceExercice._getSentence())
class SentenceState {
  int shownCount;
  double accumulatedScore;

  bool isInLearning;

  List<double> gradeValue = [0.0, 0.0, 0.0, 0.7, 1.0, 1.4]; // not allowed grade is not checked here

  SentenceState({this.shownCount = 0, this.accumulatedScore = 0.0, this.isInLearning = false});

  /// Met à jour l'état de la phrase en fonction de la note donnée
  /// appelé cette fonction une seule fois dans submitAnswer de Exercice
  void updateState(Grade grade) {
    assert(grade.q >= 0 && grade.q < gradeValue.length);

    shownCount += 1;
    accumulatedScore += gradeValue[grade.q];
    if (grade.q >= 3) {
      isInLearning = false;
    } else {
      isInLearning = true;
    }
  }

  /// Calcule le score de la phrase en pourcentage de bonnes réponses
  /// utilisé pour comparer les phrases d'un SentenceExercice et choisir la phrase à afficher
  double getscore() {
    // ce score me semble convenable, mais peut etre pas le meilleur
    if (shownCount == 0) {
      return 0.0; // == 0
    }
    if (isInLearning) {
      return double.infinity; // > 1
    }
    return accumulatedScore / shownCount; // <= 1
  }
}
