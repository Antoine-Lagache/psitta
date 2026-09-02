import 'package:psitta/infrastructure/persistence/models/sentence/sentence_state_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/sentence/sentence_state_persistence.dart';

/// Persistence representation of one sentence and its learning state.
class SentenceInstancePersistence {
  final int? id;
  final int contentId;
  final SentenceStatePersistence sentenceState;

  SentenceInstancePersistence({
    this.id,
    required this.contentId,
    required this.sentenceState,
  });

  factory SentenceInstancePersistence.fromRow(
    Map<String, Object?> sentenceInstanceRow,
    Map<String, Object?> sentenceStateRow,
  ) {
    return SentenceInstancePersistence(
      id: sentenceInstanceRow['id'] as int,
      contentId: sentenceInstanceRow['content_id'] as int,
      sentenceState: SentenceStatePersistence.fromRow(sentenceStateRow),
    );
  }

  Map<String, Object?> toRow() {
    return {'id': id, 'content_id': contentId};
  }
}
