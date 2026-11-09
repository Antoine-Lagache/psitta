import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/repositories/progress_repository.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late ProgressRepository repository;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    repository = ProgressRepository(
      testDatabase.database,
      migrationRunner: createMigrationRunner(),
    );
  });

  tearDown(() => testDatabase.dispose());

  test('restores a backup repeatedly and preserves relational integrity', () async {
    await testDatabase.insertContent();
    final backup = await repository.createDatabaseBackup();
    await testDatabase.insertContent();

    await repository.restoreDatabaseBackup(backup, allowMigration: false);
    expect(await testDatabase.countRows('content'), 1);
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
}
