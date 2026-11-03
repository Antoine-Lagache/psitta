part of 'exercise_persistence.dart';

/// Persistence shape of a character or reading exercise.
final class CharacterExercisePersistence extends ExercisePersistence {
  final int contentId;

  const CharacterExercisePersistence({
    super.id,
    required super.srsState,
    required super.trainingCountMax,
    required this.contentId,
  });

  factory CharacterExercisePersistence.fromRow(
    Map<String, Object?> exerciseRow,
    Map<String, Object?> characterRow,
    SrsStatePersistence srsState,
  ) {
    return CharacterExercisePersistence(
      id: exerciseRow['id'] as int?,
      srsState: srsState,
      trainingCountMax: exerciseRow['training_count_max'] as int,
      contentId: characterRow['content_id'] as int,
    );
  }

  Map<String, Object?> toCharacterExerciseRow(int exerciseId) => {
    'exercise_id': exerciseId,
    'content_id': contentId,
  };
}
