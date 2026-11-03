import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/exercise/character_exercise.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';

/// Translates character exercises and initializes their FSRS and training state.
class CharacterExerciseMapper {
  const CharacterExerciseMapper();

  static CharacterExercise characterToDomain(CharacterExercisePersistence persistence, bool hasHistory) {
    return CharacterExercise(
      id: persistence.id!,
      status: hasHistory ? ExerciseStatus.toReview : ExerciseStatus.newExercise,
      srsState: SRSStateMapper.toDomainSrsState(
        persistence.srsState,
        exerciseId: persistence.id!,
      ),
      contentId: persistence.contentId,
      trainingCountMax: persistence.trainingCountMax,
    );
  }

  static CharacterExercisePersistence characterToPersistence(CharacterExercise domain) {
    return CharacterExercisePersistence(
      id: domain.id,
      srsState: SRSStateMapper.toPersistenceSrsState(domain.srsState),
      trainingCountMax: domain.trainingCountMax,
      contentId: domain.contentId,
    );
  }

  static CharacterExercisePersistence newCharacterExercise(
    int contentId, {
    int trainingCountMax = 0,
    int? id,
  }) {
    return CharacterExercisePersistence(
      id: id,
      srsState: SRSStateMapper.toPersistenceSrsState(SRSState()),
      trainingCountMax: trainingCountMax,
      contentId: contentId,
    );
  }
}
