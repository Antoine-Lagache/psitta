/// Configuration parameters for the Spaced Repetition System (SRS).
class SRSConfig {
  /// Recall target and model coefficients used by the scheduling formula.
  final double rstar;
  final double wMaxFactor;
  final List<double> lambdas;
  final int easyInterval; // Days assigned when leaving learning with Easy.
  final double efMin;
  final int iMax;
  final double defaultEF;
  final double defaultW;
  final double defaultKFactor;

  final double mu;
  final int longPause;
  final double minTolFactor;

  /// Intra-session delays applied while an exercise is in learning mode.
  final List<Duration> learningSteps;
  final double hardReviewFactor;
  final double hardLearningFactor;
  final double easyBonus;
  /// Offset from midnight used to decide whether an interval crosses a day.
  final Duration dayBoundary;

  /// Maximum numbers of new and due exercises loaded into a session.
  final int newCount;
  final int reviewCount;

  static const List<double> _defaultLambdas = [0.60, 0.90, 0.80, 0.95, 0.85, 0.70];

  SRSConfig({
    this.rstar = 0.9,
    this.wMaxFactor = 0.95,
    List<double>? lambdas,
    this.easyInterval = 4,
    this.efMin = 1.3,
    this.iMax = 5 * 365,
    this.defaultEF = 2.5,
    this.defaultW = 0.0,
    this.defaultKFactor = 0.1,
    this.mu = 0.03,
    this.longPause = 60,
    this.minTolFactor = 0.2,
    List<Duration> learningSteps = const [
      Duration(minutes: 1),
      Duration(minutes: 10),
      Duration(days: 1),
    ],
    this.hardReviewFactor = 1.2,
    this.hardLearningFactor = 0.7,
    this.easyBonus = 1.3,
    this.dayBoundary = Duration.zero,
    this.newCount = 10,
    this.reviewCount = 9999,
  // TODO(review): Decide whether an empty [learningSteps] configuration is
  // supported; the learning-state `good` path indexes its last element.
  }) : lambdas = List.unmodifiable(
         List.generate(6, (i) {
           if (lambdas != null && i < lambdas.length) return lambdas[i].clamp(0.0, 1.0);
           return _defaultLambdas[i];
         }),
       ),
       learningSteps = List.unmodifiable(learningSteps),
       assert(rstar > 0 && rstar < 1),
       assert(wMaxFactor > 0 && wMaxFactor < 1);

  double get wMax => wMaxFactor * rstar;

  double getLambda(int q) {
    final int idx = q.clamp(0, lambdas.length - 1);
    return lambdas[idx];
  }
}
