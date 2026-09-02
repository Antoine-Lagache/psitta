import 'package:psitta/domain/srs/srs_state.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';

export 'package:psitta/domain/srs/srs_state.dart';
export 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';

class SRSStateMapper {
  const SRSStateMapper();

  static SRSState toDomainSrsState(SrsStatePersistence persistence) {
    return SRSState(
      easeFactor: persistence.easeFactor,
      interval: safeToDuration(persistence.interval),
      kFactor: persistence.kFactor,
      w: persistence.w,
      rbar: persistence.rBar,
      learningStepIndex: persistence.learningStepIndex,
      lastReview: safeParseDate(persistence.lastReview),
    );
  }

  static SrsStatePersistence toPersistenceSrsState(SRSState domain) {
    return SrsStatePersistence(
      easeFactor: domain.easeFactor,
      interval: safeFromDuration(domain.interval),
      kFactor: domain.kFactor,
      w: domain.w,
      rBar: domain.rbar,
      learningStepIndex: domain.learningStepIndex,
      lastReview: toIsoUtc(domain.lastReview),
      nextReview: domain.nextReview?.microsecondsSinceEpoch,
    );
  }
}
