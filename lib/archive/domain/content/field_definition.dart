/// Defines the structure and rendering behavior of a content field.
class FieldDefinition {
  final int id;
  final String name;
  final FieldValueType valueType;
  final FieldRenderer renderer;
  final FieldSide side;

  FieldDefinition({
    required this.id,
    required this.name,
    required this.valueType,
    required this.renderer,
    required this.side,
  });
}

enum FieldValueType { things, todo }

enum FieldRenderer { none, text, image, audio, html }

enum FieldSide { front, back, both }
