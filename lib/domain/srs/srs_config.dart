
class SRSConfig {
  final List<int> learningSteps; // en minutes
  final List<int> relearningSteps; // en minutes
  final int graduatingInterval; // en jours
  final double easeFactor; // multiplicateur
  final int lapsesInterval; // en minutes

  SRSConfig({
    required this.learningSteps,
    required this.relearningSteps,
    required this.graduatingInterval,
    required this.easeFactor,
    required this.lapsesInterval,
  });
}