import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/srs/sentence_state.dart';

typedef SentenceProgressEntry = ({
  SentenceInstanceProgressId id,
  SentenceState state,
});

class SentenceInstanceProgressMapper {
  const SentenceInstanceProgressMapper();

  static SentenceProgressEntry toDomain(Map<String, Object?> row) {
    final learning = row['is_in_learning'];
    if (learning != 0 && learning != 1) {
      throw StateError('Invalid sentence learning flag: $learning');
    }
    return (
      id: SentenceInstanceProgressId((
        ExerciseProgressId(row['exercise_progress_id'] as int),
        row['sentence_id'] as int,
      )),
      state: SentenceState(
        shownCount: row['shown_count'] as int,
        accumulatedScore: (row['accumulated_score'] as num).toDouble(),
        isInLearning: learning == 1,
      ),
    );
  }

  static Map<String, Object?> toPersistence(
    SentenceInstanceProgressId id,
    SentenceState state,
  ) => {
    'exercise_progress_id': id.exerciseProgressId.value,
    'sentence_id': id.sentenceId,
    'shown_count': state.shownCount,
    'accumulated_score': state.accumulatedScore,
    'is_in_learning': state.isInLearning ? 1 : 0,
  };
}
