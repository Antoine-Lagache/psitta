part of 'exercise_persistence.dart';

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
