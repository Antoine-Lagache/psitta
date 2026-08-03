import 'package:psitta/utils/conversion/time_conversion.dart';

class SrsStatePersistence {
  final double easeFactor;
  final int interval;
  final double kFactor;
  final double w;
  final double rBar;
  final DateTime? lastReview;

  SrsStatePersistence({
    required this.easeFactor,
    required this.interval,
    required this.kFactor,
    required this.w,
    required this.rBar,
    this.lastReview,
  });

  factory SrsStatePersistence.fromRow(Map<String, Object?> row) {
    return SrsStatePersistence(
      easeFactor: row['ease_factor'] as double,
      interval: row['interval'] as int,
      kFactor: row['kfactor'] as double,
      w: row['w'] as double,
      rBar: row['rbar'] as double,
      lastReview: safeParseDate(row['last_review'] as String?),
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
      'last_review': toIsoUtc(lastReview),
    };
  }
}
