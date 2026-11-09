import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/repositories/database_backup_repository.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late DatabaseBackupRepository repository;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    repository = DatabaseBackupRepository(
      testDatabase.database,
      migrationRunner: createMigrationRunner(),
    );
  });

  tearDown(() => testDatabase.dispose());

  test('restores a backup repeatedly and preserves relational integrity', () async {
    await testDatabase.insertContent();
    await testDatabase.database.execute(
      "INSERT INTO exercise (id, type, training_count_max) VALUES (1, 'word', 0)",
    );
    await testDatabase.database.execute(
      'INSERT INTO word_exercise (exercise_id, content_id) VALUES (1, 1)',
    );
    final backup = await repository.createDatabaseBackup();
    await testDatabase.insertContent();

    await repository.restoreDatabaseBackup(backup, allowMigration: false);
    expect(await testDatabase.countRows('content'), 1);
    expect(await testDatabase.countRows('word_exercise'), 1);
    expect(await testDatabase.database.getAll('PRAGMA foreign_key_check'), isEmpty);

    await repository.restoreDatabaseBackup(backup, allowMigration: false);
    expect(await testDatabase.countRows('content'), 1);
    expect(await testDatabase.database.getAll('PRAGMA foreign_key_check'), isEmpty);
  });

  test('rejects an invalid backup without changing the active database', () async {
    await testDatabase.insertContent();

    await expectLater(
      repository.inspectDatabaseBackup(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );

    expect(await testDatabase.countRows('content'), 1);
  });
  test('rolls back deletions if an insert fails during restoration', () async {
    await testDatabase.insertContent();
    await testDatabase.database.execute(
      "CREATE TRIGGER reject_restore BEFORE INSERT ON content "
      "WHEN NEW.id = 1 BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
    );
    final backup = await repository.createDatabaseBackup();
    await testDatabase.insertContent();
    await expectLater(
      repository.restoreDatabaseBackup(backup, allowMigration: false),
      throwsA(isA<Exception>()),
    );
    expect(await testDatabase.countRows('content'), 2);
    await testDatabase.database.writeLock((tx) async {
      expect((await tx.get('PRAGMA foreign_keys'))['foreign_keys'], 1);
    });
  });

}
