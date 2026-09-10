import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/migrations/database_migration.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create(migrate: false);
    database = testDatabase.database;
  });

  tearDown(() => testDatabase.dispose());

  group('MigrationRunner', () {
    test('creates the complete initial schema and records its version', () async {
      await createMigrationRunner().migrate(database);

      final version = await database.get('PRAGMA user_version;');
      final tableRows = await database.readTransaction(
        (transaction) => transaction.getAll('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table'
            AND name NOT LIKE 'sqlite_%'
          ORDER BY name
          '''),
      );

      expect(version['user_version'], 1);
      expect(
        tableRows.map((row) => row['name']),
        orderedEquals([
          'active_session_exercise',
          'content',
          'exercise',
          'exercise_history',
          'field_definition',
          'field_value',
          'media',
          'sentence_exercise',
          'sentence_group',
          'sentence_instance',
          'sentence_state',
          'session_result',
          'session_result_status_count',
          'srs_state',
          'word_exercise',
        ]),
      );
    });

    test('sorts pending migrations and does not reapply them', () async {
      final appliedVersions = <int>[];
      final runner = MigrationRunner(
        migrations: [
          _RecordingMigration(version: 2, appliedVersions: appliedVersions),
          _RecordingMigration(version: 1, appliedVersions: appliedVersions),
        ],
      );

      await runner.migrate(database);
      await runner.migrate(database);

      final version = await database.get('PRAGMA user_version;');
      expect(appliedVersions, [1, 2]);
      expect(version['user_version'], 2);
    });

    test('rolls back a failed migration and its version update', () async {
      final runner = MigrationRunner(migrations: [_FailingMigration()]);

      await expectLater(runner.migrate(database), throwsA(isA<StateError>()));

      final version = await database.get('PRAGMA user_version;');
      final tableRows = await database.readTransaction(
        (transaction) => transaction.getAll('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table' AND name = 'should_be_rolled_back'
          '''),
      );
      expect(version['user_version'], 0);
      expect(tableRows, isEmpty);
    });
  });
}

final class _RecordingMigration implements DatabaseMigration {
  @override
  final int version;

  final List<int> appliedVersions;

  _RecordingMigration({required this.version, required this.appliedVersions});

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    appliedVersions.add(version);
    await database.execute('CREATE TABLE migration_$version (id INTEGER PRIMARY KEY)');
  }
}

final class _FailingMigration implements DatabaseMigration {
  @override
  int get version => 1;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('CREATE TABLE should_be_rolled_back (id INTEGER PRIMARY KEY)');
    throw StateError('Migration failed');
  }
}
