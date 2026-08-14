import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';

class ExerciseMapper {
  const ExerciseMapper();

  static WordExercise wordToDomain(WordExercisePersistence persistence, bool hasHistory) {
    return WordExercise(
      id: persistence.id!,
      status: hasHistory ? ExerciseStatus.toReview : ExerciseStatus.newExercise,
      srsState: _toDomainSrsState(persistence.srsState),

      contentId: persistence.contentId,
    );
  }

  static WordExercisePersistence wordToPersistence(WordExercise domain) {
    return WordExercisePersistence(
      id: domain.id,
      srsState: _toPersistenceSrsState(domain.srsState),
      contentId: domain.contentId,
    );
  }

  static WordExercisePersistence newWordExercise(int contentId, {int? id}) {
    return WordExercisePersistence(
      id: id,
      srsState: _toPersistenceSrsState(SRSState()),
      contentId: contentId,
    );
  }

  static SentenceExercise sentenceToDomain(
    SentenceExercisePersistence persistence,
    bool hasHistory,
    SentenceGroup sentences,
  ) {
    return SentenceExercise(
      id: persistence.id!,
      status: hasHistory ? ExerciseStatus.toReview : ExerciseStatus.newExercise,
      srsState: _toDomainSrsState(persistence.srsState),

      sentences: sentences,
      trainingCountMax: persistence.trainingCountMax,
    );
  }

  static SentenceExercisePersistence sentenceToPersistence(SentenceExercise domain) {
    return SentenceExercisePersistence(
      id: domain.id,
      srsState: _toPersistenceSrsState(domain.srsState),
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
      srsState: _toPersistenceSrsState(SRSState()),
      sentenceGroupId: sentenceGroupId,
      trainingCountMax: trainingCountMax,
    );
  }

  static SRSState _toDomainSrsState(SrsStatePersistence persistence) {
    return SRSState(
      easeFactor: persistence.easeFactor,
      interval: safeToDuration(persistence.interval),
      kFactor: persistence.kFactor,
      w: persistence.w,
      rbar: persistence.rBar,
      lastReview: safeParseDate(persistence.lastReview),
    );
  }

  static SrsStatePersistence _toPersistenceSrsState(SRSState domain) {
    return SrsStatePersistence(
      easeFactor: domain.easeFactor,
      interval: safeFromDuration(domain.interval),
      kFactor: domain.kFactor,
      w: domain.w,
      rBar: domain.rbar,
      lastReview: toIsoUtc(domain.lastReview),
      nextReview: domain.nextReview?.microsecondsSinceEpoch,
    );
  }
}
