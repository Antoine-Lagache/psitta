import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';

/// Binds a reusable field definition to one ordered content value.
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
