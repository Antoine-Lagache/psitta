import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';

export 'package:psitta/domain/exercise/word_exercise.dart';
export 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';

class WordExerciseMapper {
  const WordExerciseMapper();

  static WordExercise wordToDomain(WordExercisePersistence persistence, bool hasHistory) {
    return WordExercise(
      id: persistence.id!,
      status: hasHistory ? ExerciseStatus.toReview : ExerciseStatus.newExercise,
      srsState: SRSStateMapper.toDomainSrsState(persistence.srsState),

      contentId: persistence.contentId,
    );
  }

  static WordExercisePersistence wordToPersistence(WordExercise domain) {
    return WordExercisePersistence(
      id: domain.id,
      srsState: SRSStateMapper.toPersistenceSrsState(domain.srsState),
      contentId: domain.contentId,
    );
  }

  static WordExercisePersistence newWordExercise(int contentId, {int? id}) {
    return WordExercisePersistence(
      id: id,
      srsState: SRSStateMapper.toPersistenceSrsState(SRSState()),
      contentId: contentId,
    );
  }
}
