import 'package:psitta/domain/srs/grade.dart';

export 'package:psitta/domain/srs/grade.dart';

/// Tracks per-sentence performance used to select the least-known sentence.
class SentenceState {
  int shownCount;
  double accumulatedScore;

  bool isInLearning;

  static const double scoreDecayFactor = 1.1;

  static const List<double> gradeWeights = [
    0.0, // allowed q=0
    0.0,
    0.0,
    0.7, // allowed q=3
    1.0, // allowed q=4
    1.4,
  ]; // Callers are responsible for enforcing exercise-specific grade rules.

  SentenceState({
    this.shownCount = 0,
    this.accumulatedScore = 0.0,
    this.isInLearning = false,
  });

  /// Incorporates one answer into this sentence's selection state.
  void updateChosenState(Grade grade) {
    assert(grade.q >= 0 && grade.q < gradeWeights.length);

    shownCount += 1;
    accumulatedScore += gradeWeights[grade.q];
    if (grade.isFail) {
      isInLearning = true;
    } else {
      isInLearning = false;
    }
  }

  /// Update others sentence_states of the group
  /// This make sure that the same sentence is not choosen
  void updateOtherState() {
    accumulatedScore = accumulatedScore / scoreDecayFactor;
  }

  /// Returns a score used to prioritize lower-performing sentences.
  double getscore() {
    if (shownCount == 0) {
      return 0.0; // == 0
    }
    if (isInLearning) {
      return double.negativeInfinity; // < 0
    }
    // Successful answers contribute their configured weight to the mean.
    return accumulatedScore / shownCount;
  }
}
