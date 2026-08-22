import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';

/// A content field composed of a definition and a value.
class Field {
  final int? id;
  final FieldDefinition definition;
  final FieldValue value;
  final int displayOrder;

  Field({
    required this.id,
    required this.definition,
    required this.value,
    required this.displayOrder,
  });
}
