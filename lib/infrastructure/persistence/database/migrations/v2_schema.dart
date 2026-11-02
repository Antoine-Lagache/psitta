import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:fsrs/fsrs.dart' as fsrs;
import 'database_migration.dart';

/// Update all table for the version 0.2.0 of Psitta
///
/// This includes:
/// - Migration of the old SRS to the FSRS-6 algorithm
class V2Schema implements DatabaseMigration {
  @override
  int get version => 2;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    // get all history entrys to calculate the new SRS state for each exercise
    final historyRows = await database.getAll(
      '''
      SELECT * 
      FROM exercise_history
      WHERE status != ?
      ORDER BY exercise_id, answered_at ASC
      ''',
      [ExerciseStatus.consolidating.code],
    );

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
        due TEXT,
        last_review TEXT
      );
    ''');

    // Create new SRS state for each exercise based on the history
    final cards = _createCardFromHistory(historyRows);
    if (cards.isNotEmpty) {
      final values = List.filled(cards.length, '(?, ?, ?, ?, ?, ?, ?)').join(', ');
      final parameters = cards
          .expand(
            (card) => [
              card.cardId,
              card.state.index,
              card.step,
              card.stability,
              card.difficulty,
              toIsoUtc(card.due),
              toIsoUtc(card.lastReview),
            ],
          )
          .toList();

      // Insert the new SRS state into the database
      await database.execute('''
        INSERT INTO srs_state (
          exercise_id, state, step, stability, difficulty, due, last_review
        ) VALUES $values
        ''', parameters);
    }
  }

  List<fsrs.Card> _createCardFromHistory(List<Map<String, dynamic>> historyRows) {
    final Map<int, fsrs.Card> cards = {};
    for (final row in historyRows) {
      final exerciseId = row['exercise_id'] as int;
      final card = cards.putIfAbsent(exerciseId, () => fsrs.Card(cardId: exerciseId));

      final answeredAt = safeParseDate(row['answered_at'] as String)!;
      final grade = switch (row['grade'] as int) {
        0 || 2 => fsrs.Rating.again,
        3 => fsrs.Rating.hard,
        4 => fsrs.Rating.good,
        5 => fsrs.Rating.easy,
        _ => throw ArgumentError('Invalid grade value: ${row['grade']}'),
      };

      final scheduler = fsrs.Scheduler(enableFuzzing: false);
      cards[exerciseId] = scheduler
          .reviewCard(card, grade, reviewDateTime: answeredAt.toUtc())
          .card;
    }

    return cards.values.toList();
  }
}
