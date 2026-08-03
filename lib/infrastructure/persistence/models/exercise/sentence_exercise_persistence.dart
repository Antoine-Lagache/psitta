part of 'exercise_persistence.dart';

final class SentenceExercisePersistence extends ExercisePersistence {
  final int sentenceGroupId;

  const SentenceExercisePersistence({
    super.id,
    required super.createdAt,
    required super.srsState,
    required this.sentenceGroupId,
  });

  factory SentenceExercisePersistence.fromRow(
    Map<String, Object?> exerciseRow,
    Map<String, Object?> sentenceRow,
    SrsStatePersistence srsState,
  ) {
    return SentenceExercisePersistence(
      id: exerciseRow['id'] as int?,
      createdAt: ExercisePersistence.parseCreatedAt(exerciseRow),
      srsState: srsState,
      sentenceGroupId: sentenceRow['sentence_group_id'] as int,
    );
  }

  Map<String, Object?> toSentenceExerciseRow(int exerciseId) {
    return {'exercise_id': exerciseId, 'sentence_group_id': sentenceGroupId};
  }
}
