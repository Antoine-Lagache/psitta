import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';

export 'package:psitta/domain/exercise/sentence_exercise.dart';
export 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';

class SentenceExerciseMapper {
  const SentenceExerciseMapper();

  static SentenceExercise sentenceToDomain(
    SentenceExercisePersistence persistence,
    bool hasHistory,
    SentenceGroup sentences,
  ) {
    return SentenceExercise(
      id: persistence.id!,
      status: hasHistory ? ExerciseStatus.toReview : ExerciseStatus.newExercise,
      srsState: SRSStateMapper.toDomainSrsState(persistence.srsState),

      sentences: sentences,
      trainingCountMax: persistence.trainingCountMax,
    );
  }

  static SentenceExercisePersistence sentenceToPersistence(SentenceExercise domain) {
    return SentenceExercisePersistence(
      id: domain.id,
      srsState: SRSStateMapper.toPersistenceSrsState(domain.srsState),
      sentenceGroupId: domain.groupId,
      trainingCountMax: domain.trainingCountMax,
    );
  }

  static SentenceExercisePersistence newSentenceExercise(
    int sentenceGroupId,
    int trainingCountMax, {
    int? id,
  }) {
    return SentenceExercisePersistence(
      id: id,
      srsState: SRSStateMapper.toPersistenceSrsState(SRSState()),
      sentenceGroupId: sentenceGroupId,
      trainingCountMax: trainingCountMax,
    );
  }
}
