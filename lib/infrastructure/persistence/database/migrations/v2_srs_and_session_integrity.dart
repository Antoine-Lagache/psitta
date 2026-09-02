import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

class V2SrsAndSessionIntegrity implements DatabaseMigration {
  @override
  int get version => 2;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('''
      ALTER TABLE srs_state
      ADD COLUMN learning_step_index INTEGER NOT NULL DEFAULT 0;
    ''');

    await database.execute('''
      CREATE TABLE active_session_exercise_v2 (
        session_result_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        status_index INTEGER NOT NULL,
        training_count INTEGER,

        PRIMARY KEY (session_result_id, exercise_id),

        FOREIGN KEY (session_result_id)
          REFERENCES session_result(id)
          ON DELETE CASCADE,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE
      );
    ''');

    await database.execute('''
      INSERT INTO active_session_exercise_v2
        (session_result_id, exercise_id, status_index, training_count)
      SELECT session_result_id, exercise_id, status_index, training_count
      FROM active_session_exercise;
    ''');

    await database.execute('DROP TABLE active_session_exercise;');
    await database.execute(
      'ALTER TABLE active_session_exercise_v2 RENAME TO active_session_exercise;',
    );
  }
}
