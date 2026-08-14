import 'package:psitta/archive/domain/content/field_definition.dart';
import 'package:psitta/archive/domain/content/field_value.dart';

/// A content field composed of a definition and a value.
class Field {
  final FieldDefinition definition;
  final FieldValue value;
  final int displayOrder;

  Field({required this.definition, required this.value, required this.displayOrder});
}
