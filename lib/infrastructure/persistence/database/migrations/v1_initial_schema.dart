import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

class V1InitialSchema implements DatabaseMigration {
  @override
  int get version => 1;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('PRAGMA foreign_keys = ON;');

    await database.execute('''
      CREATE TABLE exercise (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL
      );
    ''');

    await database.execute('''
      CREATE TABLE content (
        id INTEGER PRIMARY KEY
      );
    ''');

    await database.execute('''
      CREATE TABLE field_definition (
        id INTEGER PRIMARY KEY,
        value_type TEXT NOT NULL,
        side TEXT NOT NULL
      );
    ''');

    await database.execute('''
      CREATE TABLE media (
        id INTEGER PRIMARY KEY,
        path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size INTEGER NOT NULL,
        checksum TEXT
      );
    ''');

    await database.execute('''
      CREATE TABLE sentence_group (
        id INTEGER PRIMARY KEY
      );
    ''');

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

    await database.execute('''
      CREATE TABLE session_result (
        id INTEGER PRIMARY KEY,
        session_type_index INTEGER NOT NULL,

        number_unique_exercises_completed INTEGER NOT NULL,

        started_at TEXT,
        end_at TEXT
      );
    ''');

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
