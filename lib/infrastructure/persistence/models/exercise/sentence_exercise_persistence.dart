part of 'exercise_persistence.dart';

final class SentenceExercisePersistence extends ExercisePersistence {
  final int sentenceGroupId;

  final int trainingCountMax;

  const SentenceExercisePersistence({
    super.id,
    required super.srsState,
    required this.sentenceGroupId,
    required this.trainingCountMax,
  });

  factory SentenceExercisePersistence.fromRow(
    Map<String, Object?> exerciseRow,
    Map<String, Object?> sentenceRow,
    SrsStatePersistence srsState,
  ) {
    return SentenceExercisePersistence(
      id: exerciseRow['id'] as int?,
      srsState: srsState,
      sentenceGroupId: sentenceRow['sentence_group_id'] as int,
      trainingCountMax: sentenceRow['training_count'] as int,
    );
  }

  Map<String, Object?> toSentenceExerciseRow(int exerciseId) {
    return {
      'exercise_id': exerciseId,
      'sentence_group_id': sentenceGroupId,
      'training_count': trainingCountMax,
    };
  }
}
