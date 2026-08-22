/// Defines the structure and rendering behavior of a content field.
class FieldDefinition {
  final int id;
  final FieldValueType valueType;
  final FieldSide side;

  FieldDefinition({required this.id, required this.valueType, required this.side});
}

enum FieldValueType {
  html,
  image,
  audio,
  text;

  static FieldValueType fromString(String string) {
    return FieldValueType.values.firstWhere((e) => e.name == string);
  }
}

enum FieldSide {
  front,
  back,
  both;

  static FieldSide fromString(String string) {
    return FieldSide.values.firstWhere((e) => e.name == string);
  }
}
