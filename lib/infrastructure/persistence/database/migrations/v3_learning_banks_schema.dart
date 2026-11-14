import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

/// Adds the v0.3 bank, progress, and session schema.
///
/// Legacy content columns remain temporarily so the application keeps working
/// while the next implementation step moves content into bank changes.
class V3LearningBanksSchema implements DatabaseMigration {
  @override
  int get version => 3;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('''
      CREATE TABLE bank_commit (
        uid TEXT PRIMARY KEY NOT NULL,
        parent_uid TEXT,
        is_frozen INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (parent_uid)
          REFERENCES bank_commit(uid)
      );
      ''');

    await database.execute('''
      CREATE TABLE bank_change (
        commit_uid TEXT NOT NULL,
        change_id INTEGER NOT NULL,

        previous_commit_uid TEXT,
        previous_change_id INTEGER,
        
        change_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,

        PRIMARY KEY (commit_uid, change_id),

        FOREIGN KEY (commit_uid)
          REFERENCES bank_commit(uid)
          ON DELETE CASCADE,

        FOREIGN KEY (previous_commit_uid, previous_change_id)
          REFERENCES bank_change(commit_uid, change_id)
      );
      ''');

    await database.execute('''
      CREATE INDEX bank_change_previous_ref_idx
      ON bank_change (previous_commit_uid, previous_change_id);
      ''');

    await database.execute('''
      CREATE UNIQUE INDEX media_sha256_unique_idx ON media (sha256);
      ''');

    await database.execute('''
      CREATE TABLE learning_bank (
        id INTEGER PRIMARY KEY,
        head_commit_uid TEXT NOT NULL,

        FOREIGN KEY (head_commit_uid)
          REFERENCES bank_commit(uid)
          ON DELETE RESTRICT
      );
      ''');

    await database.execute('''
      CREATE TABLE exercise_progress (
        id INTEGER PRIMARY KEY,
        learning_bank_id INTEGER NOT NULL,
        exercise_id TEXT NOT NULL,
        
        active_commit_uid TEXT NOT NULL,
        active_change_id INTEGER NOT NULL,

        UNIQUE (learning_bank_id, exercise_id),
        FOREIGN KEY (learning_bank_id)
          REFERENCES learning_bank(id) ON DELETE CASCADE,
        FOREIGN KEY (active_commit_uid, active_change_id)
          REFERENCES bank_change(commit_uid, change_id) ON DELETE RESTRICT
      );
      ''');

    await database.execute('''
      CREATE TABLE sentence_instance_progress (
        exercise_progress_id INTEGER NOT NULL,
        sentence_id TEXT NOT NULL,
        shown_count INTEGER NOT NULL,
        accumulated_score REAL NOT NULL,
        is_in_learning INTEGER NOT NULL,
        PRIMARY KEY (exercise_progress_id, sentence_id),
        FOREIGN KEY (exercise_progress_id)
          REFERENCES exercise_progress(id) ON DELETE CASCADE
      );
      ''');

    // Transitional nullable references keep the current application working.
    // A later 0.3 step will populate them and remove the legacy exercise IDs.
    await database.execute('''
      ALTER TABLE srs_state
      ADD COLUMN exercise_progress_id INTEGER
        REFERENCES exercise_progress(id) ON DELETE CASCADE;
      ''');
    await database.execute('''
      ALTER TABLE exercise_history
      ADD COLUMN exercise_progress_id INTEGER
        REFERENCES exercise_progress(id) ON DELETE CASCADE;
      ''');
    await database.execute('''
      ALTER TABLE exercise_history
      ADD COLUMN sentence_id TEXT;
      ''');
    await database.execute('''
      ALTER TABLE session_result
      ADD COLUMN learning_bank_id INTEGER
        REFERENCES learning_bank(id) ON DELETE CASCADE;
      ''');
    await database.execute('''
      ALTER TABLE session_result
      ADD COLUMN bank_commit_uid TEXT
        REFERENCES bank_commit(uid) ON DELETE RESTRICT;
      ''');
    await database.execute('''
      ALTER TABLE active_session_exercise
      ADD COLUMN exercise_progress_id INTEGER
        REFERENCES exercise_progress(id) ON DELETE CASCADE;
      ''');
  }
}
