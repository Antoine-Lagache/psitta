import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/migrations/v1_initial_schema.dart';
import 'package:psitta/infrastructure/persistence/database/migrations/v2_schema.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create(migrate: false);
    database = testDatabase.database;
    await MigrationRunner(migrations: [V1InitialSchema()]).migrate(database);
  });

  tearDown(() => testDatabase.dispose());

  group('V2Schema', () {
    test('replays graded history and seeds every exercise', () async {
      await database.writeTransaction((transaction) async {
        for (final exerciseId in [10, 20, 30]) {
          await _insertLegacyExercise(transaction, exerciseId);
        }
        // Exercise 10 has two events at the same timestamp. The lower history
        // ID must be replayed first, regardless of insertion order.
        await _insertHistory(
          transaction,
          id: 101,
          exerciseId: 10,
          grade: 0,
          answeredAt: '2026-01-01T00:00:00.000Z',
        );
        await _insertHistory(
          transaction,
          id: 100,
          exerciseId: 10,
          grade: 4,
          answeredAt: '2026-01-01T00:00:00.000Z',
        );
        await _insertHistory(
          transaction,
          id: 102,
          exerciseId: 10,
          grade: 2,
          answeredAt: '2026-01-03T00:00:00.000Z',
        );
        await _insertHistory(
          transaction,
          id: 103,
          exerciseId: 10,
          grade: 3,
          answeredAt: '2026-01-08T00:00:00.000Z',
        );
        await _insertHistory(
          transaction,
          id: 104,
          exerciseId: 10,
          grade: 5,
          answeredAt: '2026-01-20T00:00:00.000Z',
        );
        // This grade must not affect scheduling because it was training.
        await _insertHistory(
          transaction,
          id: 105,
          exerciseId: 10,
          grade: 0,
          answeredAt: '2026-01-21T00:00:00.000Z',
          status: ExerciseStatus.consolidating.code,
        );
        // Exercise 20 has only a training event; exercise 30 has no history.
        await _insertHistory(
          transaction,
          id: 106,
          exerciseId: 20,
          grade: 4,
          answeredAt: '2026-01-10T00:00:00.000Z',
          status: ExerciseStatus.consolidating.code,
        );
      });

      await createMigrationRunner().migrate(database);

      final rows = await database.getAll(
        'SELECT * FROM srs_state ORDER BY exercise_id',
      );
      expect(rows, hasLength(3));

      final scheduler = fsrs.Scheduler(enableFuzzing: false);
      var expected = fsrs.Card(cardId: 10, due: DateTime.utc(1970));
      for (final (String timestamp, fsrs.Rating rating) in [
        ('2026-01-01T00:00:00.000Z', fsrs.Rating.good),
        ('2026-01-01T00:00:00.000Z', fsrs.Rating.again),
        ('2026-01-03T00:00:00.000Z', fsrs.Rating.again),
        ('2026-01-08T00:00:00.000Z', fsrs.Rating.hard),
        ('2026-01-20T00:00:00.000Z', fsrs.Rating.easy),
      ]) {
        expected = scheduler
            .reviewCard(
              expected,
              rating,
              reviewDateTime: DateTime.parse(timestamp).toUtc(),
            )
            .card;
      }

      _expectPersistedCard(rows[0], expected);
      for (final row in rows.skip(1)) {
        expect(row['state'], fsrs.State.learning.value);
        expect(row['step'], 0);
        expect(row['stability'], isNull);
        expect(row['difficulty'], isNull);
        expect(row['due'], DateTime.utc(1970).microsecondsSinceEpoch);
        expect(row['last_review'], isNull);
      }

      expect(await testDatabase.countRows('exercise_history'), 6);
      expect((await database.get('PRAGMA user_version'))['user_version'], 2);
    });

    test('inserts states in bounded batches and keeps the cascade foreign key', () async {
      const exerciseCount = 205;
      await database.writeTransaction((transaction) async {
        for (var exerciseId = 1; exerciseId <= exerciseCount; exerciseId++) {
          await transaction.execute(
            "INSERT INTO exercise (id, type) VALUES (?, 'word')",
            [exerciseId],
          );
        }
      });

      await createMigrationRunner().migrate(database);

      expect(await testDatabase.countRows('srs_state'), exerciseCount);
      final foreignKeys = await database.getAll('PRAGMA foreign_key_list(srs_state)');
      expect(
        foreignKeys.any(
          (row) =>
              row['table'] == 'exercise' &&
              row['from'] == 'exercise_id' &&
              row['to'] == 'id' &&
              row['on_delete'] == 'CASCADE',
        ),
        isTrue,
      );

      await database.execute('DELETE FROM exercise WHERE id = ?', [1]);
      expect(
        await database.get('SELECT COUNT(*) AS count FROM srs_state WHERE exercise_id = 1'),
        containsPair('count', 0),
      );
    });

    test('rolls back the schema replacement when legacy history is invalid', () async {
      await database.writeTransaction((transaction) async {
        await _insertLegacyExercise(transaction, 10);
        await _insertHistory(
          transaction,
          id: 1,
          exerciseId: 10,
          grade: 1,
          answeredAt: '2026-01-01T00:00:00.000Z',
        );
      });

      await expectLater(createMigrationRunner().migrate(database), throwsArgumentError);

      expect((await database.get('PRAGMA user_version'))['user_version'], 1);
      final legacyState = await database.get(
        'SELECT interval FROM srs_state WHERE exercise_id = 10',
      );
      expect(legacyState['interval'], 1);
    });
  });
}

Future<void> _insertLegacyExercise(sqlite.SqliteWriteContext transaction, int id) async {
  await transaction.execute(
    "INSERT INTO exercise (id, type) VALUES (?, 'word')",
    [id],
  );
  await transaction.execute(
    '''
    INSERT INTO srs_state (
      exercise_id, ease_factor, interval, kfactor, w, rbar,
      learning_step_index, last_review, next_review
    ) VALUES (?, 2.5, 1, 1.0, 1.0, 0.9, 0, NULL, NULL)
    ''',
    [id],
  );
}

Future<void> _insertHistory(
  sqlite.SqliteWriteContext transaction, {
  required int id,
  required int exerciseId,
  required int grade,
  required String answeredAt,
  int status = 4,
}) async {
  await transaction.execute(
    '''
    INSERT INTO exercise_history (id, exercise_id, grade, answered_at, status)
    VALUES (?, ?, ?, ?, ?)
    ''',
    [id, exerciseId, grade, answeredAt, status],
  );
}

void _expectPersistedCard(Map<String, Object?> row, fsrs.Card card) {
  expect(row['exercise_id'], card.cardId);
  expect(row['state'], card.state.value);
  expect(row['step'], card.step);
  expect(row['stability'], closeTo(card.stability!, 1e-9));
  expect(row['difficulty'], closeTo(card.difficulty!, 1e-9));
  expect(row['due'], card.due.microsecondsSinceEpoch);
  expect(row['last_review'], card.lastReview?.microsecondsSinceEpoch);
}
