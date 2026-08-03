class FieldDefinitionPersistence {
  final int? id;
  final String name;
  final String valueType;
  final String renderer;
  final String side;

  FieldDefinitionPersistence({
    this.id,
    required this.name,
    required this.valueType,
    required this.renderer,
    required this.side,
  });

  factory FieldDefinitionPersistence.fromRow(Map<String, Object?> fieldDefinitionRow) {
    return FieldDefinitionPersistence(
      id: fieldDefinitionRow['id'] as int?,
      name: fieldDefinitionRow['name'] as String,
      valueType: fieldDefinitionRow['value_type'] as String,
      renderer: fieldDefinitionRow['renderer'] as String,
      side: fieldDefinitionRow['side'] as String,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'name': name,
      'value_type': valueType,
      'renderer': renderer,
      'side': side,
    };
  }
}
