part of 'exercise_persistence.dart';

/// Persistence shape of a word exercise subtype.
final class WordExercisePersistence extends ExercisePersistence {
  final int contentId;

  const WordExercisePersistence({
    super.id,
    required super.srsState,
    required this.contentId,
  });

  factory WordExercisePersistence.fromRow(
    Map<String, Object?> exerciseRow,
    Map<String, Object?> wordRow,
    SrsStatePersistence srsState,
  ) {
    if (exerciseRow['training_count_max'] != 0) {
      throw StateError('Word exercises must not have additional training');
    }
    return WordExercisePersistence(
      id: exerciseRow['id'] as int?,
      srsState: srsState,
      contentId: wordRow['content_id'] as int,
    );
  }

  Map<String, Object?> toWordExerciseRow(int exerciseId) {
    return {'exercise_id': exerciseId, 'content_id': contentId};
  }
}
