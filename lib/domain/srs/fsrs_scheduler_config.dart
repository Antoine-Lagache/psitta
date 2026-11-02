import 'package:fsrs/fsrs.dart' as fsrs;

/// Application configuration for constructing an FSRS scheduler.
///
/// The algorithm defaults match dart-fsrs. Fuzzing is disabled by default so
/// interval previews and submitted answers produce the same result.
class FsrsSchedulerConfig {
  final List<double> parameters;
  final double desiredRetention;
  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;
  final int maximumInterval;
  final bool enableFuzzing;

  FsrsSchedulerConfig({
    List<double> parameters = fsrs.defaultParameters,
    this.desiredRetention = 0.9,
    List<Duration> learningSteps = const [Duration(minutes: 1), Duration(minutes: 10)],
    List<Duration> relearningSteps = const [Duration(minutes: 10)],
    this.maximumInterval = 36500,
    this.enableFuzzing = false,
  }) : parameters = List.unmodifiable(parameters),
       learningSteps = List.unmodifiable(learningSteps),
       relearningSteps = List.unmodifiable(relearningSteps) {
    if (!desiredRetention.isFinite || desiredRetention <= 0 || desiredRetention >= 1) {
      throw ArgumentError.value(
        desiredRetention,
        'desiredRetention',
        'Must be greater than 0 and less than 1',
      );
    }
    if (maximumInterval <= 0) {
      throw ArgumentError.value(maximumInterval, 'maximumInterval', 'Must be positive');
    }
    if ([...this.learningSteps, ...this.relearningSteps].any((step) => step.isNegative)) {
      throw ArgumentError('Learning and relearning steps must not be negative');
    }
  }

  /// Builds a fresh scheduler so each session uses this configuration.
  fsrs.Scheduler createScheduler() => fsrs.Scheduler(
    parameters: parameters,
    desiredRetention: desiredRetention,
    learningSteps: learningSteps,
    relearningSteps: relearningSteps,
    maximumInterval: maximumInterval,
    enableFuzzing: enableFuzzing,
  );
}
