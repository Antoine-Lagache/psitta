import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/migrations/v1_initial_schema.dart';
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

  group('FSRS migrations', () {
    test('moves sentence training configuration and creates character table', () async {
      await database.writeTransaction((transaction) async {
        await transaction.execute('INSERT INTO content (id) VALUES (20)');
        await transaction.execute('INSERT INTO sentence_group (id) VALUES (30)');
        await transaction.execute(
          "INSERT INTO exercise (id, type) VALUES (10, 'sentence')",
        );
        await transaction.execute('''
          INSERT INTO sentence_exercise (exercise_id, sentence_group_id, training_count)
          VALUES (10, 30, 2)
          ''');
        await transaction.execute('''
          INSERT INTO srs_state (
            exercise_id, ease_factor, interval, kfactor, w, rbar,
            learning_step_index, last_review, next_review
          ) VALUES (10, 2.5, 1, 1.0, 1.0, 0.9, 0, NULL, NULL)
          ''');
      });

      await createMigrationRunner().migrate(database);

      final exercise = await database.get(
        'SELECT training_count_max FROM exercise WHERE id = 10',
      );
      final sentence = await database.get(
        'SELECT exercise_id, sentence_group_id FROM sentence_exercise WHERE exercise_id = 10',
      );
      final sentenceColumns = await database.readTransaction((transaction) async {
        final rows = await transaction.getAll('PRAGMA table_info(sentence_exercise)');
        return rows.map((row) => row['name']).toList();
      });
      final characterTable = await database.get(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'character_exercise'",
      );

      expect(exercise['training_count_max'], 2);
      expect(sentence, {'exercise_id': 10, 'sentence_group_id': 30});
      expect(sentenceColumns, ['exercise_id', 'sentence_group_id']);
      expect(characterTable['name'], 'character_exercise');
      final settingsTable = await database.get(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_setting'",
      );
      expect(settingsTable['name'], 'app_setting');
    });

    test('replays history then converts its grades to FSRS ratings in V2', () async {
      await database.writeTransaction((transaction) async {
        await _insertLegacyExercise(transaction, 10);
        for (final (int id, int legacyGrade) in [
          (100, 0),
          (101, 2),
          (102, 3),
          (103, 4),
          (104, 5),
        ]) {
          await _insertHistory(
            transaction,
            id: id,
            exerciseId: 10,
            grade: legacyGrade,
            answeredAt: DateTime.utc(2026, 1, id - 99).toIso8601String(),
          );
        }
      });

      await createMigrationRunner().migrate(database);

      final rows = await database.getAll(
        'SELECT grade FROM exercise_history ORDER BY id',
      );
      expect(rows.map((row) => row['grade']), [1, 1, 2, 3, 4]);
      expect((await database.get('PRAGMA user_version'))['user_version'], 2);
    });

    test('rejects invalid grades even in history excluded from replay', () async {
      await database.writeTransaction((transaction) async {
        await _insertLegacyExercise(transaction, 10);
        await _insertHistory(
          transaction,
          id: 1,
          exerciseId: 10,
          grade: 1,
          answeredAt: '2026-01-01T00:00:00.000Z',
          status: ExerciseStatus.consolidating.code,
        );
      });

      await expectLater(createMigrationRunner().migrate(database), throwsArgumentError);

      expect((await database.get('PRAGMA user_version'))['user_version'], 1);
      expect(
        (await database.get('SELECT grade FROM exercise_history WHERE id = 1'))['grade'],
        1,
      );
    });

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

      final rows = await database.getAll('SELECT * FROM srs_state ORDER BY exercise_id');
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

      expect(await testDatabase.countRows('exercise_history'), 7);
      final trainingGrades = await database.getAll(
        'SELECT id, grade FROM exercise_history WHERE id IN (105, 106) ORDER BY id',
      );
      expect(trainingGrades.map((row) => row['grade']), [1, 3]);
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
      final srsTable = await database.get(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'srs_state'",
      );
      expect(srsTable['sql'], contains('ON DELETE CASCADE'));

      await database.execute('DELETE FROM exercise WHERE id = ?', [1]);
      expect(
        await database.get(
          'SELECT COUNT(*) AS count FROM srs_state WHERE exercise_id = 1',
        ),
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
  await transaction.execute("INSERT INTO exercise (id, type) VALUES (?, 'word')", [id]);
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
