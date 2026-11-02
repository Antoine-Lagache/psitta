import 'package:psitta/domain/srs/fsrs_scheduler_config.dart';
import 'package:test/test.dart';

void main() {
  test('uses FSRS scheduler defaults except deterministic fuzzing', () {
    final config = FsrsSchedulerConfig();
    final scheduler = config.createScheduler();

    expect(scheduler.parameters, hasLength(21));
    expect(scheduler.desiredRetention, 0.9);
    expect(scheduler.learningSteps, const [Duration(minutes: 1), Duration(minutes: 10)]);
    expect(scheduler.relearningSteps, const [Duration(minutes: 10)]);
    expect(scheduler.maximumInterval, 36500);
    expect(scheduler.enableFuzzing, isFalse);
  });

  test('allows overriding scheduler values without exposing mutable lists', () {
    final steps = [const Duration(minutes: 2)];
    final config = FsrsSchedulerConfig(
      desiredRetention: 0.85,
      learningSteps: steps,
      maximumInterval: 5000,
      enableFuzzing: true,
    );
    steps.add(const Duration(minutes: 3));

    final scheduler = config.createScheduler();
    expect(scheduler.desiredRetention, 0.85);
    expect(scheduler.learningSteps, const [Duration(minutes: 2)]);
    expect(scheduler.maximumInterval, 5000);
    expect(scheduler.enableFuzzing, isTrue);
    expect(
      () => config.learningSteps.add(const Duration(minutes: 4)),
      throwsUnsupportedError,
    );
  });
}
