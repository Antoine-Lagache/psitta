import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

/// Adds the local bank registry and the bank commit/change history tables.
///
/// The existing content tables remain in place in this first schema step.
/// Migrating their rows into a root commit requires the finalized exercise
/// change payload format and is intentionally handled separately.
class V3LearningBanksSchema implements DatabaseMigration {
  @override
  int get version => 3;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('''
      CREATE TABLE bank_commit (
        uid TEXT PRIMARY KEY NOT NULL,
        parent_uid TEXT,
        is_frozen INTEGER NOT NULL DEFAULT 0
          CHECK (is_frozen IN (0, 1)),

        CHECK (parent_uid IS NULL OR parent_uid <> uid),

        FOREIGN KEY (parent_uid)
          REFERENCES bank_commit(uid)
          ON DELETE RESTRICT
      );
      ''');

    await database.execute('''
      CREATE TABLE bank_change (
        commit_uid TEXT NOT NULL,
        change_id INTEGER NOT NULL CHECK (change_id >= 0),
        previous_commit_uid TEXT,
        previous_change_id INTEGER,
        change_type TEXT NOT NULL CHECK (length(trim(change_type)) > 0),
        payload_json TEXT NOT NULL
          CHECK (json_valid(payload_json) AND json_type(payload_json) = 'object'),

        PRIMARY KEY (commit_uid, change_id),
        CHECK (
          (previous_commit_uid IS NULL AND previous_change_id IS NULL)
          OR
          (previous_commit_uid IS NOT NULL AND previous_change_id IS NOT NULL
            AND previous_commit_uid <> commit_uid
            AND previous_change_id >= 0)
        ),

        FOREIGN KEY (commit_uid)
          REFERENCES bank_commit(uid)
          ON DELETE CASCADE,

        FOREIGN KEY (previous_commit_uid, previous_change_id)
          REFERENCES bank_change(commit_uid, change_id)
          ON DELETE RESTRICT
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

    // Frozen commits and their changes are immutable. Commit deletion remains
    // available when no bank or descendant references the commit.
    await database.execute('''
      CREATE TRIGGER bank_commit_frozen_update
      BEFORE UPDATE ON bank_commit
      WHEN OLD.is_frozen = 1
      BEGIN
        SELECT RAISE(ABORT, 'A frozen bank commit is immutable');
      END;
      ''');

    await database.execute('''
      CREATE TRIGGER bank_change_frozen_insert
      BEFORE INSERT ON bank_change
      WHEN (SELECT is_frozen FROM bank_commit WHERE uid = NEW.commit_uid) = 1
      BEGIN
        SELECT RAISE(ABORT, 'Cannot add a change to a frozen bank commit');
      END;
      ''');

    await database.execute('''
      CREATE TRIGGER bank_change_frozen_update
      BEFORE UPDATE ON bank_change
      WHEN (SELECT is_frozen FROM bank_commit WHERE uid = OLD.commit_uid) = 1
      BEGIN
        SELECT RAISE(ABORT, 'Cannot edit a change in a frozen bank commit');
      END;
      ''');

  }
}
