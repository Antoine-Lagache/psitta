import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

/// Creates every table required by the initial MVP data model.
class V1InitialSchema implements DatabaseMigration {
  @override
  int get version => 1;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    // TODO(review): Verify that enabling foreign keys inside the migration
    // transaction is effective for every SQLite connection used by sqlite_async.
    await database.execute('PRAGMA foreign_keys = ON;');

    // Stores the shared identity and subtype discriminator of every exercise.
    await database.execute('''
      CREATE TABLE exercise (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL
      );
    ''');

    // Owns the ordered field values rendered as an exercise side.
    await database.execute('''
      CREATE TABLE content (
        id INTEGER PRIMARY KEY
      );
    ''');

    // Defines reusable field metadata: value type and visible side.
    await database.execute('''
      CREATE TABLE field_definition (
        id INTEGER PRIMARY KEY,
        value_type TEXT NOT NULL,
        side TEXT NOT NULL
      );
    ''');

    // Stores metadata used to locate and deduplicate media files.
    await database.execute('''
      CREATE TABLE media (
        id INTEGER PRIMARY KEY,
        path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size INTEGER NOT NULL,
        sha256 TEXT NOT NULL
      );
    ''');

    // Identifies a collection of interchangeable sentence instances.
    await database.execute('''
      CREATE TABLE sentence_group (
        id INTEGER PRIMARY KEY
      );
    ''');

    // Stores the scheduling state associated one-to-one with an exercise.
    // TODO(review): Decide whether the current learning-step index belongs in
    // the initial schema; loading an exercise currently restores its default.
    await database.execute('''
      CREATE TABLE srs_state (
        exercise_id INTEGER PRIMARY KEY,

        ease_factor REAL NOT NULL,
        interval INTEGER NOT NULL,
        kfactor REAL NOT NULL,
        w REAL NOT NULL,
        rbar REAL NOT NULL,
        last_review TEXT,
        next_review INTEGER,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE
    );
    ''');

    // Stores the word-exercise subtype and its content reference.
    await database.execute('''
      CREATE TABLE word_exercise (
        exercise_id INTEGER PRIMARY KEY,
        content_id INTEGER NOT NULL,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE,

        FOREIGN KEY (content_id)
          REFERENCES content(id)
    );
    ''');

    // Stores the sentence-exercise subtype and its training configuration.
    await database.execute('''
      CREATE TABLE sentence_exercise (
        exercise_id INTEGER PRIMARY KEY,
        sentence_group_id INTEGER NOT NULL,
        training_count INTEGER NOT NULL,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE,

        FOREIGN KEY (sentence_group_id)
          REFERENCES sentence_group(id)
          ON DELETE CASCADE,
        
        UNIQUE (sentence_group_id)  
    );
    ''');

    // Associates one content item and its progress with a sentence group.
    await database.execute('''
      CREATE TABLE sentence_instance (
        id INTEGER PRIMARY KEY,
        sentence_group_id INTEGER NOT NULL,
        content_id INTEGER NOT NULL,

        FOREIGN KEY (sentence_group_id)
          REFERENCES sentence_group(id) 
          ON DELETE CASCADE,

        FOREIGN KEY (content_id)
          REFERENCES content(id)
      );
    ''');

    // Stores selection and learning progress for one sentence instance.
    await database.execute('''
      CREATE TABLE sentence_state (
        sentence_instance_id INTEGER PRIMARY KEY,

        shown_count INTEGER NOT NULL,
        accumulated_score REAL NOT NULL,
        is_in_learning INTEGER NOT NULL,

        FOREIGN KEY (sentence_instance_id)
          REFERENCES sentence_instance(id)
          ON DELETE CASCADE
    );
    ''');

    // Records immutable answer events for exercises and optional sentences.
    await database.execute('''
      CREATE TABLE exercise_history (
        id INTEGER PRIMARY KEY,

        exercise_id INTEGER NOT NULL,

        sentence_instance_id INTEGER,

        grade INTEGER NOT NULL,
        answered_at TEXT NOT NULL,
        status INTEGER NOT NULL,

        FOREIGN KEY (exercise_id)
          REFERENCES exercise(id)
          ON DELETE CASCADE,
        
        FOREIGN KEY (sentence_instance_id)
          REFERENCES sentence_instance(id)
          ON DELETE CASCADE
      );
    ''');

    // Stores one ordered, typed value belonging to a content item.
    await database.execute('''
      CREATE TABLE field_value (
        id INTEGER PRIMARY KEY,

        content_id INTEGER NOT NULL,
        field_definition_id INTEGER NOT NULL,

        text_value TEXT,
        media_id INTEGER,

        display_order INTEGER NOT NULL,

        FOREIGN KEY (content_id)
          REFERENCES content(id)
          ON DELETE CASCADE,

        FOREIGN KEY (field_definition_id)
          REFERENCES field_definition(id)
          ON DELETE CASCADE,

        FOREIGN KEY (media_id)
          REFERENCES media(id)
      );
    ''');

    // Stores the lifecycle and aggregate outcome of a learning session.
    await database.execute('''
      CREATE TABLE session_result (
        id INTEGER PRIMARY KEY,
        session_type_index INTEGER NOT NULL,

        number_unique_exercises_completed INTEGER NOT NULL,

        started_at TEXT,
        end_at TEXT
      );
    ''');

    // Normalizes per-status answer counts for a session result.
    await database.execute('''
      CREATE TABLE session_result_status_count (
        id_session_result INTEGER NOT NULL,
        status_index INTEGER NOT NULL,
        number_exercise_completed INTEGER NOT NULL,

        PRIMARY KEY (
          id_session_result,
          status_index
        ),

        FOREIGN KEY (id_session_result)
          REFERENCES session_result(id)
          ON DELETE CASCADE
      );
    ''');

    // Snapshots exercise state needed to resume an unfinished session.
    // TODO(review): Decide whether exercise_id should reference exercise(id)
    // so a snapshot cannot outlive its exercise.
    await database.execute('''
      CREATE TABLE active_session_exercise (
        session_result_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        
        status_index INTEGER NOT NULL,

        training_count INTEGER,


        PRIMARY KEY (
            session_result_id,
            exercise_id
        ),

        FOREIGN KEY (session_result_id)
            REFERENCES session_result(id)
            ON DELETE CASCADE
    );
    ''');
  }
}
