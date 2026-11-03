part of 'exercise_persistence.dart';

/// Persistence shape of a kana character or reading exercise.
final class KanaExercisePersistence extends ExercisePersistence {
  final int contentId;

  const KanaExercisePersistence({
    super.id,
    required super.srsState,
    required super.trainingCountMax,
    required this.contentId,
  });

  factory KanaExercisePersistence.fromRow(
    Map<String, Object?> exerciseRow,
    Map<String, Object?> kanaRow,
    SrsStatePersistence srsState,
  ) {
    return KanaExercisePersistence(
      id: exerciseRow['id'] as int?,
      srsState: srsState,
      trainingCountMax: exerciseRow['training_count_max'] as int,
      contentId: kanaRow['content_id'] as int,
    );
  }

  Map<String, Object?> toKanaExerciseRow(int exerciseId) => {
    'exercise_id': exerciseId,
    'content_id': contentId,
  };
}
