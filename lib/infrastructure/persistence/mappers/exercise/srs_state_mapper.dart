import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';

export 'package:psitta/domain/srs/srs_state.dart';
export 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';

/// Converts FSRS card state between the domain and persistence layers.
class SRSStateMapper {
  const SRSStateMapper();

  static SRSState toDomainSrsState(
    SrsStatePersistence persistence, {
    required int exerciseId,
  }) {
    return SRSState(
      exerciseId: exerciseId,
      state: fsrs.State.fromValue(persistence.state),
      step: persistence.step,
      stability: persistence.stability,
      difficulty: persistence.difficulty,
      due: DateTime.fromMicrosecondsSinceEpoch(persistence.due, isUtc: true),
      lastReview: persistence.lastReview == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(persistence.lastReview!, isUtc: true),
    );
  }

  static SrsStatePersistence toPersistenceSrsState(SRSState domain) {
    return SrsStatePersistence(
      state: domain.state.value,
      step: domain.step,
      stability: domain.stability,
      difficulty: domain.difficulty,
      due: domain.due.microsecondsSinceEpoch,
      lastReview: domain.lastReview?.microsecondsSinceEpoch,
    );
  }
}
