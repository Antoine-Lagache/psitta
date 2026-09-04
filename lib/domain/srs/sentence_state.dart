import 'package:psitta/domain/srs/grade.dart';

export 'package:psitta/domain/srs/grade.dart';

/// Tracks per-sentence performance used to select the least-known sentence.
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
  ]; // Callers are responsible for enforcing exercise-specific grade rules.

  SentenceState({
    this.shownCount = 0,
    this.accumulatedScore = 0.0,
    this.isInLearning = false,
  });

  /// Incorporates one answer into this sentence's selection state.
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
