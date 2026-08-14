import 'package:psitta/domain/sentences/sentence_group.dart';
import 'package:psitta/domain/sentences/sentence_instance.dart';
import 'package:psitta/domain/srs/sentence_state.dart';
import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';

class SentenceMapper {
  const SentenceMapper();

  static SentenceGroup toDomain(SentenceGroupPersistence persistence) {
    return SentenceGroup(
      id: persistence.id!,
      sentences: persistence.sentenceInstances.map(_toDomainSentenceInstance).toList(),
    );
  }

  static SentenceGroupPersistence toPersistence(SentenceGroup domain) {
    return SentenceGroupPersistence(
      id: domain.id,
      sentenceInstances: domain.sentences.map(_toPersistenceSentenceInstance).toList(),
    );
  }

  static SentenceGroupPersistence resetGroupProgress(
    SentenceGroupPersistence sentenceGroup,
  ) {
    return SentenceGroupPersistence(
      id: sentenceGroup.id,
      sentenceInstances: sentenceGroup.sentenceInstances
          .map(
            (instance) => SentenceInstancePersistence(
              id: instance.id,
              contentId: instance.contentId,
              sentenceState: _toPersistenceSentenceState(SentenceState()),
            ),
          )
          .toList(),
    );
  }

  static SentenceInstancePersistence newInstance(int contentId) {
    return SentenceInstancePersistence(
      contentId: contentId,
      sentenceState: _toPersistenceSentenceState(SentenceState()),
    );
  }

  static SentenceState _toDomainSentenceState(SentenceStatePersistence persistence) {
    return SentenceState(
      shownCount: persistence.shownCount,
      accumulatedScore: persistence.accumulatedScore,
      isInLearning: persistence.isInLearning,
    );
  }

  static SentenceStatePersistence _toPersistenceSentenceState(SentenceState domain) {
    return SentenceStatePersistence(
      shownCount: domain.shownCount,
      accumulatedScore: domain.accumulatedScore,
      isInLearning: domain.isInLearning,
    );
  }

  static SentenceInstance _toDomainSentenceInstance(
    SentenceInstancePersistence persistence,
  ) {
    return SentenceInstance(
      id: persistence.id!,
      contentId: persistence.contentId,
      state: _toDomainSentenceState(persistence.sentenceState),
    );
  }

  static SentenceInstancePersistence _toPersistenceSentenceInstance(
    SentenceInstance domain,
  ) {
    return SentenceInstancePersistence(
      id: domain.id,
      contentId: domain.contentId,
      sentenceState: _toPersistenceSentenceState(domain.state),
    );
  }
}
