import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/exercise/kana_exercise.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';

/// Translates kana exercises and initializes their FSRS and training state.
class KanaExerciseMapper {
  const KanaExerciseMapper();

  static KanaExercise kanaToDomain(KanaExercisePersistence persistence, bool hasHistory) {
    return KanaExercise(
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

  static KanaExercisePersistence kanaToPersistence(KanaExercise domain) {
    return KanaExercisePersistence(
      id: domain.id,
      srsState: SRSStateMapper.toPersistenceSrsState(domain.srsState),
      trainingCountMax: domain.trainingCountMax,
      contentId: domain.contentId,
    );
  }

  static KanaExercisePersistence newKanaExercise(
    int contentId, {
    int trainingCountMax = 0,
    int? id,
  }) {
    return KanaExercisePersistence(
      id: id,
      srsState: SRSStateMapper.toPersistenceSrsState(SRSState()),
      trainingCountMax: trainingCountMax,
      contentId: contentId,
    );
  }
}
