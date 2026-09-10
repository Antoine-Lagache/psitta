import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';
import 'package:psitta/application/models/content/media.dart';
import 'package:psitta/infrastructure/persistence/dao/field_definition_dao.dart';
import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late ContentRepository repository;
  late FieldDefinitionDao fieldDefinitionDao;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    repository = ContentRepository(database);
    fieldDefinitionDao = FieldDefinitionDao(database);
  });

  tearDown(() => testDatabase.dispose());

  Future<FieldDefinition> createDefinition(
    FieldValueType valueType,
    FieldSide side,
  ) async {
    final id = await fieldDefinitionDao.insert(
      FieldDefinitionPersistence(valueType: valueType.name, side: side.name),
    );
    return FieldDefinition(id: id, valueType: valueType, side: side);
  }

  group('ContentRepository', () {
    test('round-trips typed text fields in display order', () async {
      final frontDefinition = await createDefinition(
        FieldValueType.text,
        FieldSide.front,
      );
      final backDefinition = await createDefinition(FieldValueType.html, FieldSide.back);
      final content = Content(
        id: null,
        fields: [
          Field(
            id: null,
            definition: backDefinition,
            value: const TextFieldValue('<strong>answer</strong>'),
            displayOrder: 2,
          ),
          Field(
            id: null,
            definition: frontDefinition,
            value: const TextFieldValue('question'),
            displayOrder: 1,
          ),
        ],
      );

      final contentId = await repository.insert(content);
      final persisted = await repository.getById(contentId);

      expect(persisted, isNotNull);
      expect(persisted!.id, contentId);
      expect(persisted.fields, hasLength(2));

      final frontField = persisted.fields.first;
      expect(frontField.id, isNotNull);
      expect(frontField.displayOrder, 1);
      expect(frontField.definition.id, frontDefinition.id);
      expect(frontField.definition.valueType, FieldValueType.text);
      expect(frontField.definition.side, FieldSide.front);
      expect((frontField.value as TextFieldValue).value, 'question');

      final backField = persisted.fields.last;
      expect(backField.id, isNotNull);
      expect(backField.displayOrder, 2);
      expect(backField.definition.id, backDefinition.id);
      expect(backField.definition.valueType, FieldValueType.html);
      expect(backField.definition.side, FieldSide.back);
      expect((backField.value as TextFieldValue).value, '<strong>answer</strong>');
    });

    test('persists media metadata and supports hash lookup', () async {
      final definition = await createDefinition(FieldValueType.image, FieldSide.front);
      final content = Content(
        id: null,
        fields: [
          Field(
            id: null,
            definition: definition,
            value: MediaFieldValue(
              Media(
                id: null,
                path: 'media/example.png',
                mimeType: 'image/png',
                size: 2048,
                sha256: 'image-sha256',
              ),
            ),
            displayOrder: 0,
          ),
        ],
      );

      final contentId = await repository.insert(content);
      final persisted = await repository.getById(contentId);
      final fieldValue = persisted!.fields.single.value as MediaFieldValue;
      final media = fieldValue.media;

      expect(media.id, isNotNull);
      expect(media.path, 'media/example.png');
      expect(media.mimeType, 'image/png');
      expect(media.size, 2048);
      expect(media.sha256, 'image-sha256');

      final byHash = await MediaRepository(database).getBySHA256('image-sha256');
      expect(byHash!.id, media.id);
      expect(byHash.path, media.path);
      expect(await MediaRepository(database).getBySHA256('unknown'), isNull);
    });

    test('update replaces the complete ordered field collection', () async {
      final firstDefinition = await createDefinition(
        FieldValueType.text,
        FieldSide.front,
      );
      final secondDefinition = await createDefinition(
        FieldValueType.text,
        FieldSide.back,
      );
      final contentId = await repository.insert(
        Content(
          id: null,
          fields: [
            Field(
              id: null,
              definition: firstDefinition,
              value: const TextFieldValue('old'),
              displayOrder: 0,
            ),
          ],
        ),
      );

      await repository.update(
        Content(
          id: contentId,
          fields: [
            Field(
              id: null,
              definition: secondDefinition,
              value: const TextFieldValue('replacement'),
              displayOrder: 0,
            ),
          ],
        ),
      );

      final persisted = await repository.getById(contentId);
      expect(persisted!.fields, hasLength(1));
      expect(persisted.fields.single.definition.id, secondDefinition.id);
      expect((persisted.fields.single.value as TextFieldValue).value, 'replacement');
    });

    test('insert rolls back the aggregate when a definition is missing', () async {
      final missingDefinition = FieldDefinition(
        id: 999,
        valueType: FieldValueType.text,
        side: FieldSide.front,
      );

      await expectLater(
        repository.insert(
          Content(
            id: null,
            fields: [
              Field(
                id: null,
                definition: missingDefinition,
                value: const TextFieldValue('invalid'),
                displayOrder: 0,
              ),
            ],
          ),
        ),
        throwsA(anything),
      );

      expect(await testDatabase.countRows('content'), 0);
      expect(await testDatabase.countRows('field_value'), 0);
    });

    test('delete cascades to field values', () async {
      final definition = await createDefinition(FieldValueType.text, FieldSide.front);
      final contentId = await repository.insert(
        Content(
          id: null,
          fields: [
            Field(
              id: null,
              definition: definition,
              value: const TextFieldValue('value'),
              displayOrder: 0,
            ),
          ],
        ),
      );

      await repository.delete(contentId);

      expect(await repository.getById(contentId), isNull);
      expect(await testDatabase.countRows('field_value'), 0);
    });
  });
}
