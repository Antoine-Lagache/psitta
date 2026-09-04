import 'package:psitta/infrastructure/persistence/models/sentence/sentence_instance_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/sentence/sentence_instance_persistence.dart';

/// Persistence representation of a sentence group aggregate.
class SentenceGroupPersistence {
  final int? id;
  final List<SentenceInstancePersistence> sentenceInstances;

  SentenceGroupPersistence({this.id, required this.sentenceInstances});

  factory SentenceGroupPersistence.fromRow(
    Map<String, Object?> sentenceGroupRow,
    List<SentenceInstancePersistence> instances,
  ) {
    return SentenceGroupPersistence(
      id: sentenceGroupRow['id'] as int?,
      sentenceInstances: instances,
    );
  }

  Map<String, Object?> toRow() {
    return {'id': id};
  }
}
