part of 'exercise_persistence.dart';

/// Persistence shape of a sentence exercise subtype.
final class SentenceExercisePersistence extends ExercisePersistence {
  final int sentenceGroupId;

  const SentenceExercisePersistence({
    super.id,
    required super.srsState,
    required super.trainingCountMax,
    required this.sentenceGroupId,
  });

  factory SentenceExercisePersistence.fromRow(
    Map<String, Object?> exerciseRow,
    Map<String, Object?> sentenceRow,
    SrsStatePersistence srsState,
  ) {
    return SentenceExercisePersistence(
      id: exerciseRow['id'] as int?,
      srsState: srsState,
      trainingCountMax: exerciseRow['training_count_max'] as int,
      sentenceGroupId: sentenceRow['sentence_group_id'] as int,
    );
  }

  Map<String, Object?> toSentenceExerciseRow(int exerciseId) => {
    'exercise_id': exerciseId,
    'sentence_group_id': sentenceGroupId,
  };
}
