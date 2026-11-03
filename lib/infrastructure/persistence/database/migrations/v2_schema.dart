import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:fsrs/fsrs.dart' as fsrs;
import 'database_migration.dart';

/// Updates all tables for Psitta version 0.2.0.
///
/// This includes:
/// - Migration of the old SRS to the FSRS-6 algorithm
/// - Conversion of historical grades to FSRS rating values
/// - Shared exercise training state and kana exercise persistence
class V2Schema implements DatabaseMigration {
  @override
  int get version => 2;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    // Read history and exercise IDs before replacing the old SRS table.
    final historyRows = await database.getAll(
      '''
      SELECT id, exercise_id, grade, answered_at
      FROM exercise_history
      WHERE status != ?
      ORDER BY exercise_id, answered_at ASC, id ASC
      ''',
      [ExerciseStatus.consolidating.code],
    );
    final allHistoryGrades = await database.getAll(
      'SELECT grade FROM exercise_history ORDER BY id ASC',
    );
    final exerciseRows = await database.getAll('SELECT id FROM exercise ORDER BY id ASC');
    _validateLegacyGrades(allHistoryGrades);

    await _migrateSharedExerciseSchema(database);

    // Drop old SRS table
    await database.execute('''
      DROP TABLE IF EXISTS srs_state;
    ''');

    // Create new SRS table
    await database.execute('''
      CREATE TABLE srs_state (
        exercise_id INTEGER PRIMARY KEY,
        state INTEGER NOT NULL,
        step INTEGER,
        stability REAL,
        difficulty REAL,
        due INTEGER NOT NULL,
        last_review INTEGER,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE
      );
    ''');

    // Seed every exercise, including new cards with no review history.
    final cards = {
      for (final row in exerciseRows)
        row['id'] as int: fsrs.Card(cardId: row['id'] as int, due: DateTime.utc(1970)),
    };
    _replayHistory(cards, historyRows);
    await _insertCardsInBatches(database, cards.values.toList());
    await _migrateHistoryGrades(database);
  }

  Future<void> _migrateSharedExerciseSchema(
    sqlite.SqliteWriteContext database,
  ) async {
    await database.execute('''
      ALTER TABLE exercise
      ADD COLUMN training_count_max INTEGER NOT NULL DEFAULT 0
      ''');
    await database.execute('''
      UPDATE exercise
      SET training_count_max = COALESCE((
        SELECT training_count
        FROM sentence_exercise
        WHERE sentence_exercise.exercise_id = exercise.id
      ), 0)
      WHERE type = 'sentence'
      ''');

    await database.execute('''
      CREATE TABLE sentence_exercise_v2 (
        exercise_id INTEGER PRIMARY KEY,
        sentence_group_id INTEGER NOT NULL,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE,

        FOREIGN KEY (sentence_group_id)
          REFERENCES sentence_group(id),

        UNIQUE (sentence_group_id)
      )
      ''');
    await database.execute('''
      INSERT INTO sentence_exercise_v2 (exercise_id, sentence_group_id)
      SELECT exercise_id, sentence_group_id FROM sentence_exercise
      ''');
    await database.execute('DROP TABLE sentence_exercise');
    await database.execute('ALTER TABLE sentence_exercise_v2 RENAME TO sentence_exercise');

    await database.execute('''
      CREATE TABLE kana_exercise (
        exercise_id INTEGER PRIMARY KEY,
        content_id INTEGER NOT NULL,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE,

        FOREIGN KEY (content_id)
          REFERENCES content(id)
      )
      ''');
  }

  void _validateLegacyGrades(List<Map<String, dynamic>> historyRows) {
    for (final row in historyRows) {
      switch (row['grade'] as int) {
        case 0 || 2 || 3 || 4 || 5:
          break;
        default:
          throw ArgumentError('Invalid legacy grade value: ${row['grade']}');
      }
    }
  }

  Future<void> _migrateHistoryGrades(sqlite.SqliteWriteContext database) async {
    await database.execute('''
      UPDATE exercise_history
      SET grade = CASE grade
        WHEN 0 THEN 1
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        WHEN 5 THEN 4
      END
      ''');
  }

  void _replayHistory(Map<int, fsrs.Card> cards, List<Map<String, dynamic>> historyRows) {
    final scheduler = fsrs.Scheduler(enableFuzzing: false);
    for (final row in historyRows) {
      final exerciseId = row['exercise_id'] as int;
      final card = cards[exerciseId];
      if (card == null) {
        throw StateError('History references missing exercise $exerciseId');
      }

      final answeredAt = safeParseDate(row['answered_at'] as String)!;
      final grade = switch (row['grade'] as int) {
        0 || 2 => fsrs.Rating.again,
        3 => fsrs.Rating.hard,
        4 => fsrs.Rating.good,
        5 => fsrs.Rating.easy,
        _ => throw ArgumentError('Invalid grade value: ${row['grade']}'),
      };

      cards[exerciseId] = scheduler
          .reviewCard(card, grade, reviewDateTime: answeredAt.toUtc())
          .card;
    }
  }

  Future<void> _insertCardsInBatches(
    sqlite.SqliteWriteContext database,
    List<fsrs.Card> cards,
  ) async {
    const batchSize = 100;
    for (var start = 0; start < cards.length; start += batchSize) {
      final batch = cards.skip(start).take(batchSize).toList();
      final values = List.filled(batch.length, '(?, ?, ?, ?, ?, ?, ?)').join(', ');
      final parameters = batch
          .expand(
            (card) => [
              card.cardId,
              card.state.value,
              card.step,
              card.stability,
              card.difficulty,
              card.due.microsecondsSinceEpoch,
              card.lastReview?.microsecondsSinceEpoch,
            ],
          )
          .toList();

      await database.execute('''
        INSERT INTO srs_state (
          exercise_id, state, step, stability, difficulty, due, last_review
        ) VALUES $values
        ''', parameters);
    }
  }
}
