class SrsStatePersistence {
  final double easeFactor;
  final int interval;
  final double kFactor;
  final double w;
  final double rBar;
  final String? lastReview;

  // not present in the domain, but used to determine if the exercise is due for review
  // use int (in microsecond) for calculation and comparison.
  final int? nextReview;

  SrsStatePersistence({
    required this.easeFactor,
    required this.interval,
    required this.kFactor,
    required this.w,
    required this.rBar,
    this.lastReview,
    this.nextReview,
  });

  factory SrsStatePersistence.fromRow(Map<String, Object?> row) {
    return SrsStatePersistence(
      easeFactor: row['ease_factor'] as double,
      interval: row['interval'] as int,
      kFactor: row['kfactor'] as double,
      w: row['w'] as double,
      rBar: row['rbar'] as double,
      lastReview: row['last_review'] as String?,
      nextReview: row['next_review'] as int?,
    );
  }

  Map<String, Object?> toRow(int exerciseId) {
    return {
      'exercise_id': exerciseId,
      'ease_factor': easeFactor,
      'interval': interval,
      'kfactor': kFactor,
      'w': w,
      'rbar': rBar,
      'last_review': lastReview,
      'next_review': nextReview,
    };
  }
}
