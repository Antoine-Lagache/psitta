import 'fsrs_scheduler_config.dart';

export 'fsrs_scheduler_config.dart';

/// Session limits and day boundary used by the exercise/session layer.
class SRSConfig {
  /// Parameters used by the FSRS scheduler for reviews in this session.
  final FsrsSchedulerConfig fsrsScheduler;

  /// Offset from midnight used to decide whether an interval crosses a day.
  final Duration dayBoundary;

  /// Maximum new exercises per type and due exercises per session.
  final int newCount;
  final int newSentenceCount;
  final int newCharacterCount;
  final int reviewCount;

  SRSConfig({
    FsrsSchedulerConfig? fsrsScheduler,
    this.dayBoundary = Duration.zero,
    this.newCount = 4,
    this.newSentenceCount = 3,
    this.newCharacterCount = 5,
    this.reviewCount = 9999,
  }) : fsrsScheduler = fsrsScheduler ?? FsrsSchedulerConfig();

  SRSConfig copyWith({
    int? newCount,
    int? newSentenceCount,
    int? newCharacterCount,
    int? reviewCount,
  }) => SRSConfig(
    fsrsScheduler: fsrsScheduler,
    dayBoundary: dayBoundary,
    newCount: newCount ?? this.newCount,
    newSentenceCount: newSentenceCount ?? this.newSentenceCount,
    newCharacterCount: newCharacterCount ?? this.newCharacterCount,
    reviewCount: reviewCount ?? this.reviewCount,
  );
}
