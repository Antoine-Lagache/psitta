class FieldDefinitionPersistence {
  final int? id;
  final String valueType;
  final String side;

  FieldDefinitionPersistence({this.id, required this.valueType, required this.side});

  factory FieldDefinitionPersistence.fromRow(Map<String, Object?> fieldDefinitionRow) {
    return FieldDefinitionPersistence(
      id: fieldDefinitionRow['id'] as int?,
      valueType: fieldDefinitionRow['value_type'] as String,
      side: fieldDefinitionRow['side'] as String,
    );
  }

  Map<String, Object?> toRow() {
    return {'id': id, 'value_type': valueType, 'side': side};
  }
}
