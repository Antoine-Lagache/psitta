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
    test('creates the complete current schema and records its version', () async {
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

    test('creates every column required by the persistence layer', () async {
      await createMigrationRunner().migrate(database);

      const expectedColumns = {
        'exercise': ['id', 'type'],
        'content': ['id'],
        'field_definition': ['id', 'value_type', 'side'],
        'media': ['id', 'path', 'mime_type', 'size', 'sha256'],
        'sentence_group': ['id'],
        'srs_state': [
          'exercise_id',
          'ease_factor',
          'interval',
          'kfactor',
          'w',
          'rbar',
          'learning_step_index',
          'last_review',
          'next_review',
        ],
        'word_exercise': ['exercise_id', 'content_id'],
        'sentence_exercise': [
          'exercise_id',
          'sentence_group_id',
          'training_count',
        ],
        'sentence_instance': ['id', 'sentence_group_id', 'content_id'],
        'sentence_state': [
          'sentence_instance_id',
          'shown_count',
          'accumulated_score',
          'is_in_learning',
        ],
        'exercise_history': [
          'id',
          'exercise_id',
          'sentence_instance_id',
          'grade',
          'answered_at',
          'status',
        ],
        'field_value': [
          'id',
          'content_id',
          'field_definition_id',
          'text_value',
          'media_id',
          'display_order',
        ],
        'session_result': [
          'id',
          'session_type_index',
          'number_unique_exercises_completed',
          'total_time_spent_microseconds',
          'started_at',
          'end_at',
        ],
        'session_result_status_count': [
          'id_session_result',
          'status_index',
          'number_exercise_completed',
        ],
        'active_session_exercise': [
          'session_result_id',
          'exercise_id',
          'status_index',
          'training_count',
        ],
      };

      for (final MapEntry(:key, :value) in expectedColumns.entries) {
        expect(await _columnNames(database, key), value, reason: 'Table $key');
      }
    });

    test('preserves schema and data after reopening the connection', () async {
      await createMigrationRunner().migrate(database);
      await database.execute('INSERT INTO content DEFAULT VALUES');

      await testDatabase.reopen();
      database = testDatabase.database;

      final version = await database.get('PRAGMA user_version;');
      final contentRows = await database.get('SELECT COUNT(*) AS count FROM content');
      final foreignKeys = await database.get('PRAGMA foreign_keys;');

      expect(version['user_version'], 1);
      expect(contentRows['count'], 1);
      expect(foreignKeys['foreign_keys'], 1);
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

Future<List<String>> _columnNames(sqlite.SqliteDatabase database, String table) async {
  return database.readTransaction((transaction) async {
    final columns = await transaction.getAll('PRAGMA table_info($table);');
    return columns.map((column) => column['name'] as String).toList();
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
