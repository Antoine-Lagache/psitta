import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Resets learner progress while preserving content and app preferences.
class ProgressRepository {
  final sqlite.SqliteDatabase database;

  ProgressRepository(this.database);

  Future<void> resetAllProgress() async {
    await database.writeTransaction((txn) async {
      await txn.execute(
        '''
        UPDATE srs_state
        SET state = ?, step = NULL, stability = NULL, difficulty = NULL,
            due = 0, last_review = NULL
        ''',
        [fsrs.State.learning.value],
      );
      await txn.execute('''
        UPDATE sentence_state
        SET shown_count = 0, accumulated_score = 0, is_in_learning = 0
        ''');
      await txn.execute('DELETE FROM exercise_history');
      await txn.execute('DELETE FROM session_result');
      await txn.execute(
        "DELETE FROM app_setting WHERE key LIKE 'statistics.daily_streak.%'",
      );
    });
  }

}
