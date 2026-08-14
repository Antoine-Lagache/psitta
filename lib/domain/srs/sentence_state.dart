import 'package:psitta/domain/srs/grade.dart';

export 'package:psitta/domain/srs/grade.dart';

/// Specific state for sentence exercises
/// use to choose a sentence among the group of sentences (see SentenceExercice._getSentence())
class SentenceState {
  int shownCount;
  double accumulatedScore;

  bool isInLearning;

  static const List<double> gradeWeights = [
    0.0,
    0.0,
    0.0,
    0.7,
    1.0,
    1.4,
  ]; // not allowed grade is not checked here

  SentenceState({
    this.shownCount = 0,
    this.accumulatedScore = 0.0,
    this.isInLearning = false,
  });

  /// update the state of the sentence group according to the given grade
  /// called this function only once in submitAnswer of Exercice
  void updateState(Grade grade) {
    assert(grade.q >= 0 && grade.q < gradeWeights.length);

    shownCount += 1;
    accumulatedScore += gradeWeights[grade.q];
    if (grade.q >= 3) {
      isInLearning = false;
    } else {
      isInLearning = true;
    }
  }

  /// calculate the score of the sentence in percentage of good answers
  /// used to compare the sentences of a SentenceExercice and choose the sentence to display
  /// small score means the sentence is not well known, so it should be shown more often
  double getscore() {
    if (shownCount == 0) {
      return 0.0; // == 0
    }
    if (isInLearning) {
      return double.negativeInfinity; // < 0
    }
    // This is a wheighted average of the grades, with a maximum of 1.0 (for q=4) and a minimum of 0.0 (for q=3)
    return accumulatedScore / shownCount; // <= 1
  }
}
