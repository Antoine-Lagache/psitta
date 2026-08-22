import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';

class FieldDefinitionDao {
  final sqlite.SqliteDatabase database;

  FieldDefinitionDao(this.database);

  Future<int> insert(FieldDefinitionPersistence fieldDefinition) {
    if (fieldDefinition.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final fieldDefinitionResult = await txn.execute(
        '''
          INSERT INTO field_definition (
            value_type,
            side
          )
          VALUES(?, ?)
          RETURNING id
        ''',
        [fieldDefinition.valueType, fieldDefinition.side],
      );

      return fieldDefinitionResult.first['id'] as int;
    });
  }

  Future<FieldDefinitionPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final fieldDefinitionRows = await txn.getAll(
        '''
          SELECT
            id,
            value_type,
            side
          FROM field_definition
          WHERE id = ?
        ''',
        [id],
      );

      if (fieldDefinitionRows.isEmpty) {
        return null;
      }

      return FieldDefinitionPersistence.fromRow(fieldDefinitionRows.first);
    });
  }

  Future<void> update(FieldDefinitionPersistence fieldDefinition) {
    if (fieldDefinition.id == null) {
      throw ArgumentError('Cannot update a FieldDefinition without an id');
    }

    final fieldDefinitionId = fieldDefinition.id!;

    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
          UPDATE field_definition
          SET
            value_type = ?,
            side = ?
          WHERE id = ?
        ''',
        [fieldDefinition.valueType, fieldDefinition.side, fieldDefinitionId],
      );
    });
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM field_definition
        WHERE id = ?
        ''',
        [id],
      );
    });
  }
}
