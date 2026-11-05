import 'dart:io';

import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/release/character_exercise_release_importer.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
  });

  tearDown(() => testDatabase.dispose());

  test('adds the kana release once while preserving existing exercises', () async {
    final existingContentId = await testDatabase.insertContent();
    final existingExerciseId = await ExerciseRepository(
      database,
    ).createCharacterExercise(existingContentId);

    Future<bool> importRelease() => CharacterExerciseReleaseImporter(
      database,
      loadAsset: (path) => File(path).readAsBytes(),
    ).importIfNeeded();

    expect(await importRelease(), isTrue);
    expect(
      (await database.get("SELECT COUNT(*) AS count FROM exercise WHERE type = 'character'"))[
        'count'
      ],
      310,
    );
    expect(await importRelease(), isFalse);
    expect(
      (await database.get('SELECT COUNT(*) AS count FROM exercise'))['count'],
      310,
    );
    expect(
      await database.get(
        'SELECT content_id FROM character_exercise WHERE exercise_id = ?',
        [existingExerciseId],
      ),
      containsPair('content_id', existingContentId),
    );
  });
}
