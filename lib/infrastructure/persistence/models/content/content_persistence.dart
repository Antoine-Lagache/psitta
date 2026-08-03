import 'package:psitta/infrastructure/persistence/models/content/field_value_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/content/field_value_persistence.dart';

class ContentPersistence {
  final int? id;

  final List<FieldValuePersistence> fieldValues;

  ContentPersistence({this.id, required this.fieldValues});

  factory ContentPersistence.fromRow(
    Map<String, Object?> contentRow,
    List<FieldValuePersistence> fields,
  ) {
    return ContentPersistence(id: contentRow['id'] as int?, fieldValues: fields);
  }

  Map<String, Object?> toRow() {
    return {'id': id};
  }
}
