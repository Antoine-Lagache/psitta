import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/application/models/content/content.dart';

import 'package:psitta/infrastructure/persistence/dao/content_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/field_definition_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/content_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';

/// Persists application content while hiding normalized field storage.
class ContentRepository {
  final sqlite.SqliteDatabase database;

  final ContentDao _contentDao;
  final FieldDefinitionDao _fieldDefinitionDao;

  ContentRepository(this.database)
    : _contentDao = ContentDao(database),
      _fieldDefinitionDao = FieldDefinitionDao(database);

  Future<int> insert(Content content) async {
    if (content.id != null) {
      throw ArgumentError('Cannot insert a Content that already has an id');
    }

    final persistence = ContentMapper.contentToPersistence(content);

    return await _contentDao.insert(persistence);
  }

  /// Loads content and resolves the definitions required by all its fields.
  Future<Content?> getById(int id) async {
    final persistence = await _contentDao.getById(id);

    if (persistence == null) {
      return null;
    }

    final definitions = <int, FieldDefinitionPersistence>{};

    for (final fieldValue in persistence.fieldValues) {
      final definitionId = fieldValue.fieldDefinitionId;

      if (definitions.containsKey(definitionId)) {
        continue;
      }

      final definition = await _fieldDefinitionDao.getById(definitionId);

      if (definition == null) {
        throw StateError('FieldDefinition with id $definitionId does not exist');
      }

      definitions[definitionId] = definition;
    }

    return ContentMapper.contentToDomain(persistence, definitions);
  }

  Future<void> update(Content content) async {
    if (content.id == null) {
      throw ArgumentError('Cannot update a Content without an id');
    }

    final persistence = ContentMapper.contentToPersistence(content);

    await _contentDao.update(persistence);
  }

  Future<void> delete(int id) {
    return _contentDao.delete(id);
  }
}
