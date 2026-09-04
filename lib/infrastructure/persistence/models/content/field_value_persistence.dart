import 'package:psitta/infrastructure/persistence/models/content/media_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/content/media_persistence.dart';

/// Persistence representation of one ordered text-or-media field value.
class FieldValuePersistence {
  final int? id;
  final int fieldDefinitionId;

  final String? textValue;
  final MediaPersistence? media;

  final int displayOrder;

  FieldValuePersistence({
    this.id,
    required this.fieldDefinitionId,
    this.textValue,
    this.media,
    required this.displayOrder,
  });

  factory FieldValuePersistence.fromRow(
    Map<String, Object?> fieldValueRow,
    Map<String, Object?>? mediaRow,
  ) {
    return FieldValuePersistence(
      id: fieldValueRow['id'] as int?,
      fieldDefinitionId: fieldValueRow['field_definition_id'] as int,
      textValue: fieldValueRow['text_value'] as String?,
      media: mediaRow == null ? null : MediaPersistence.fromRow(mediaRow),
      displayOrder: fieldValueRow['display_order'] as int,
    );
  }

  Map<String, Object?> toRow(int contentId) {
    return {
      'id': id,
      'content_id': contentId,
      'field_definition_id': fieldDefinitionId,
      'text_value': textValue,
      'media_id': media?.id,
      'display_order': displayOrder,
    };
  }
}
