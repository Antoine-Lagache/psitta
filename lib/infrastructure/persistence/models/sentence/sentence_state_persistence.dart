import 'package:psitta/utils/conversion/safe_numeric_conversion.dart';

class SentenceStatePersistence {
  final int shownCount;
  final double accumulatedScore;
  final bool isInLearning;

  SentenceStatePersistence({
    required this.shownCount,
    required this.accumulatedScore,
    required this.isInLearning,
  });

  factory SentenceStatePersistence.fromRow(Map<String, Object?> sentenceStateRow) {
    return SentenceStatePersistence(
      shownCount: sentenceStateRow['shown_count'] as int,
      accumulatedScore: sentenceStateRow['accumulated_score'] as double,
      isInLearning: safeToBool(sentenceStateRow['is_in_learning'], fallback: false),
    );
  }

  Map<String, Object?> toRow() {
    return {
      'shown_count': shownCount,
      'accumulated_score': accumulatedScore,
      'is_in_learning': isInLearning ? 1 : 0,
    };
  }
}
