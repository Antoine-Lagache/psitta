/// Database-safe representation of one FSRS card state.
///
/// Dates are stored as UTC microseconds since the Unix epoch so SQLite can
/// compare due times numerically without timestamp string ordering edge cases.
class SrsStatePersistence {
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final int due;
  final int? lastReview;

  const SrsStatePersistence({
    required this.state,
    required this.step,
    required this.stability,
    required this.difficulty,
    required this.due,
    required this.lastReview,
  });

  factory SrsStatePersistence.fromRow(Map<String, Object?> row) {
    return SrsStatePersistence(
      state: row['state'] as int,
      step: row['step'] as int?,
      stability: (row['stability'] as num?)?.toDouble(),
      difficulty: (row['difficulty'] as num?)?.toDouble(),
      due: row['due'] as int,
      lastReview: row['last_review'] as int?,
    );
  }

  Map<String, Object?> toRow(int exerciseId) {
    return {
      'exercise_id': exerciseId,
      'state': state,
      'step': step,
      'stability': stability,
      'difficulty': difficulty,
      'due': due,
      'last_review': lastReview,
    };
  }
}
