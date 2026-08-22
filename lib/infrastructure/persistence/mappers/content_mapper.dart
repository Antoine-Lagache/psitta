import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';
import 'package:psitta/application/models/content/media.dart';
import 'package:psitta/infrastructure/persistence/models/content/content_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';

class ContentMapper {
  const ContentMapper();

  static ContentPersistence contentToPersistence(Content domain) {
    return ContentPersistence(
      id: domain.id,
      fieldValues: domain.fields.map(fieldToPersistence).toList(),
    );
  }

  static Content contentToDomain(
    ContentPersistence persitence,
    Map<int, FieldDefinitionPersistence> definitions,
  ) {
    final List<Field> fields = [];

    for (final value in persitence.fieldValues) {
      final definition = definitions[value.fieldDefinitionId];

      if (definition == null) {
        throw StateError("fieldDefinitionPersistence missing in Map");
      }

      fields.add(fieldToDomain(value, definition));
    }

    return Content(id: persitence.id, fields: fields);
  }

  static FieldValuePersistence fieldToPersistence(Field domain) {
    switch (domain.value) {
      case TextFieldValue text:
        return FieldValuePersistence(
          id: domain.id,
          fieldDefinitionId: domain.definition.id,
          textValue: text.value,
          media: null,
          displayOrder: domain.displayOrder,
        );
      case MediaFieldValue media:
        return FieldValuePersistence(
          id: domain.id,
          fieldDefinitionId: domain.definition.id,
          textValue: null,
          media: _mediaToPersistence(media.media),
          displayOrder: domain.displayOrder,
        );
    }
  }

  static Field fieldToDomain(
    FieldValuePersistence fieldValuePersistence,
    FieldDefinitionPersistence fieldDefinitionPersistence,
  ) {
    return Field(
      id: fieldValuePersistence.id,
      definition: definitionToDomain(fieldDefinitionPersistence),
      value: _fieldValueToDomain(fieldValuePersistence),
      displayOrder: fieldValuePersistence.displayOrder,
    );
  }

  static FieldDefinitionPersistence definitionToPersistence(FieldDefinition domain) {
    return FieldDefinitionPersistence(
      id: domain.id,
      valueType: domain.valueType.name,
      side: domain.side.name,
    );
  }

  static FieldDefinition definitionToDomain(FieldDefinitionPersistence persistence) {
    return FieldDefinition(
      id: persistence.id!,
      valueType: FieldValueType.fromString(persistence.valueType),
      side: FieldSide.fromString(persistence.side),
    );
  }

  static MediaPersistence _mediaToPersistence(Media mediaDomain) {
    return MediaPersistence(
      id: mediaDomain.id,
      path: mediaDomain.path,
      mimeType: mediaDomain.mimeType,
      size: mediaDomain.size,
      checksum: mediaDomain.checksum,
    );
  }

  static Media _mediaToDomain(MediaPersistence mediaPersistence) {
    return Media(
      id: mediaPersistence.id,
      path: mediaPersistence.path,
      mimeType: mediaPersistence.mimeType,
      size: mediaPersistence.size,
      checksum: mediaPersistence.checksum,
    );
  }

  static FieldValue _fieldValueToDomain(FieldValuePersistence persistence) {
    if (persistence.textValue == null && persistence.media != null) {
      return MediaFieldValue(_mediaToDomain(persistence.media!));
    } else if (persistence.textValue != null && persistence.media == null) {
      return TextFieldValue(persistence.textValue!);
    }

    throw StateError(
      "FieldValuePersistence must have a textValue or a media but not both",
    );
  }
}
