import 'package:sqflite/sqflite.dart';
import '../legacy/domain/legacy_note.dart';
import '../legacy/domain/legacy_exercice.dart';
import '../legacy/domain/legacy_srs.dart';
import '../utils/convert_utils.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _db;

  DatabaseService._init();

  Future<Database> get database async {
    if (_db != null) return _db!;

    // Obtenir le chemin du fichier app.db
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/app.db';

    // Ouvrir la base (et créer si nécessaire)
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await initDB(db, version);  // appelle la fonction de création des tables
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE srs_configs ADD COLUMN new_count INTEGER DEFAULT 10;');
        }
      },
    );

    return _db!;
  }

  Future<void> initDB(Database db, int version) async {
    // TABLE NOTES
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,             -- JSON encodé depuis Map<String,dynamic>
        tags TEXT,
        created_time TEXT NOT NULL      -- stocké en ISO8601
      )
    ''');

    // TABLE CARD_TEMPLATES
    await db.execute('''
      CREATE TABLE card_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recto_html TEXT NOT NULL,
        verso_html TEXT NOT NULL
      )
    ''');

    // TABLE CARDS
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        template_id INTEGER NOT NULL,
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY(template_id) REFERENCES card_templates(id) ON DELETE CASCADE
      )
    ''');

    // TABLE EXERCICES
    await db.execute('''
      CREATE TABLE exercices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        available_at TEXT
      )
    ''');

    // TABLE WORD_EXERCICES
    await db.execute('''
      CREATE TABLE word_exercices (
        id INTEGER PRIMARY KEY,
        card_id INTEGER NOT NULL,
        FOREIGN KEY(id) REFERENCES exercices(id) ON DELETE CASCADE,
        FOREIGN KEY(card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    // TABLE SRS_STATES
    await db.execute('''
      CREATE TABLE srs_states (
        exercice_id INTEGER PRIMARY KEY,   -- relation 1-1 avec exercice
        next_review TEXT,
        ease_factor REAL,
        interval INTEGER,
        k_factor REAL,
        w REAL,
        rbar REAL,
        last_review TEXT,
        learning_step_index INTEGER,
        history TEXT,
        FOREIGN KEY(exercice_id) REFERENCES exercices(id) ON DELETE CASCADE
      )
    ''');

    // TABLE SRS_CONFIG
    await db.execute('''
      CREATE TABLE srs_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rstar REAL NOT NULL,
        w_max_factor REAL NOT NULL,
        lambdas TEXT NOT NULL,        -- stockée en JSON : [0.60, 0.90, ...]
        easy_interval INTEGER NOT NULL,
        first_interval_fallback INTEGER NOT NULL,
        ef_min REAL NOT NULL,
        i_max INTEGER NOT NULL,
        default_ef REAL NOT NULL,
        default_w REAL NOT NULL,
        mu REAL NOT NULL,
        long_pause INTEGER NOT NULL,
        min_tol_factor REAL NOT NULL,
        learning_steps TEXT NOT NULL, -- stockée en JSON : [ "00:01:00", "00:10:00", "01:00:00", ... ]
        hard_review_factor REAL NOT NULL,
        hard_learning_factor REAL NOT NULL,
        easy_bonus REAL NOT NULL,
        day_boundary INTEGER NOT NULL  -- stocké en milliseconde, c'est une durée ( < 24h)
        new_count INTEGER NOT NULL
      )
    ''');
  }


  // ---------- NOTES ----------

  // INSERT
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  // GET by ID
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Note.fromMap(result.first);
    }
    return null;
}

  // GET all
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query('notes');
    return result.map((row) => Note.fromMap(row)).toList();
  }

  // UPDATE
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // DELETE
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ---------- CARD_TEMPLATES ----------

  // INSERT
  Future<int> insertCardTemplate(CardTemplate template) async {
    final db = await database;
    return await db.insert('card_templates', template.toMap());
  }

  // GET by ID
  Future<CardTemplate?> getCardTemplateById(int id) async {
    final db = await database;
    final result = await db.query(
      'card_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return CardTemplate.fromMap(result.first);
    }
    return null;
  }

  // GET all
  Future<List<CardTemplate>> getAllCardTemplates() async {
    final db = await database;
    final result = await db.query('card_templates');
    return result.map((row) => CardTemplate.fromMap(row)).toList();
  }

  // UPDATE
  Future<int> updateCardTemplate(CardTemplate template) async {
    final db = await database;
    return await db.update(
      'card_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  // DELETE
  Future<int> deleteCardTemplate(int id) async {
    final db = await database;
    return await db.delete(
      'card_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ---------- CARDS ----------

  // INSERT
  Future<int> insertCard(Card card) async {
    final db = await database;
    return await db.insert('cards', card.toMap());
  }

  // Optimized: GET by ID (avec jointure)
  Future<Card?> getCardById(int id) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        c.id AS card_id,
        c.note_id,
        c.template_id,

        n.id AS note_id,
        n.data AS note_data,
        n.tags AS note_tags,
        n.created_time AS note_created,

        t.id AS template_id,
        t.recto_html,
        t.verso_html
      FROM cards c
      JOIN notes n ON c.note_id = n.id
      JOIN card_templates t ON c.template_id = t.id
      WHERE c.id = ?
    ''', [id]);

    if (result.isEmpty) return null;
    final row = result.first;

    final note = Note.fromMap({
      'id': row['note_id'],
      'data': row['note_data'],
      'tags': row['note_tags'],
      'created_time': row['note_created'],
    });

    final template = CardTemplate.fromMap({
      'id': row['template_id'],
      'recto_html': row['recto_html'],
      'verso_html': row['verso_html'],
    });

    return Card.fromMap(
      {
        'id': row['card_id'],
        'note_id': row['note_id'],
        'template_id': row['template_id'],
      },
      note,
      template,
    );
  }

  // Optimized: GET all cards for a specific note (single JOIN)
  Future<List<Card>> getCardsByNoteId(int noteId) async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT
        c.id AS card_id,
        c.note_id AS note_id,
        c.template_id AS template_id,

        n.id AS note_id_real,
        n.data AS note_data,
        n.tags AS note_tags,
        n.created_time AS note_created_time,

        t.id AS template_id_real,
        t.recto_html AS recto_html,
        t.verso_html AS verso_html
      FROM cards c
      JOIN notes n ON c.note_id = n.id
      JOIN card_templates t ON c.template_id = t.id
      WHERE c.note_id = ?
    ''', [noteId]);

    if (rows.isEmpty) return [];

    final List<Card> out = [];
    for (final row in rows) {
      final noteMap = {
        'id': row['note_id_real'],
        'data': row['note_data'],
        'tags': row['note_tags'],
        'created_time': row['note_created_time'],
      };
      final note = Note.fromMap(noteMap);

      final templateMap = {
        'id': row['template_id_real'],
        'recto_html': row['recto_html'],
        'verso_html': row['verso_html'],
      };
      final template = CardTemplate.fromMap(templateMap);

      out.add(Card.fromMap({'id': row['card_id']}, note, template));
    }

    return out;
  }

  // UPDATE
  Future<int> updateCard(Card card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // DELETE
  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ---------- WORD_EXERCICES ----------

  // INSERT
  Future<int> insertWordExercice(WordExercice exo) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      // 1) insert dans exercices (autoinc)
      final exerciceId = await txn.insert('exercices', {
        'type': exerciceTypeToText(exo.type),
        'available_at': toIsoUtc(exo.availableAt),
      });

      // 2) insert dans word_exercices avec le même id
      await txn.insert('word_exercices', {
        'id': exerciceId,
        'card_id': exo.card.id,
      });

      // 3) insert SRSState lié (exercice_id = exerciceId)
      await txn.insert('srs_states', {
        'exercice_id': exerciceId,
        'next_review': toIsoUtc(exo.srsData.nextReview),
        'ease_factor': exo.srsData.easeFactor,
        'interval': exo.srsData.interval.inMilliseconds,
        'k_factor': exo.srsData.kFactor,
        'w': exo.srsData.w,
        'rbar': exo.srsData.rbar,
        'last_review': toIsoUtc(exo.srsData.lastReview),
        'learning_step_index': exo.srsData.learningStepIndex,
        'history': safeJsonEncode(exo.srsData.history) ?? '[]',
      });

      return exerciceId;
    });
  }
  
  // Optimized: GET by ID
  Future<WordExercice?> getWordExerciceById(int id) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        e.id AS exercice_id,
        e.type,
        e.available_at,

        w.card_id,

        c.id AS card_id,
        c.note_id,
        c.template_id,

        n.id AS note_id,
        n.data AS note_data,
        n.tags AS note_tags,
        n.created_time AS note_created,

        t.id AS template_id,
        t.recto_html,
        t.verso_html,

        s.next_review,
        s.ease_factor,
        s.interval,
        s.k_factor,
        s.w,
        s.rbar,
        s.last_review,
        s.learning_step_index,
        s.history
      FROM exercices e
      JOIN word_exercices w ON e.id = w.id
      JOIN cards c ON w.card_id = c.id
      JOIN notes n ON c.note_id = n.id
      JOIN card_templates t ON c.template_id = t.id
      JOIN srs_states s ON e.id = s.exercice_id
      WHERE e.id = ?
    ''', [id]);

    if (result.isEmpty) return null;
    final row = result.first;

    final note = Note.fromMap({
      'id': row['note_id'],
      'data': row['note_data'],
      'tags': row['note_tags'],
      'created_time': row['note_created'],
    });

    final template = CardTemplate.fromMap({
      'id': row['template_id'],
      'recto_html': row['recto_html'],
      'verso_html': row['verso_html'],
    });

    final card = Card.fromMap({
      'id': row['card_id'],
      'note_id': row['note_id'],
      'template_id': row['template_id'],
    }, note, template);

    final srs = SRSState.fromMap({
      'next_review': row['next_review'],
      'ease_factor': row['ease_factor'],
      'interval': row['interval'],
      'k_factor': row['k_factor'],
      'w': row['w'],
      'rbar': row['rbar'],
      'last_review': row['last_review'],
      'learning_step_index': row['learning_step_index'],
      'history': row['history'],
    });

    return WordExercice.fromMap({
      'id': row['exercice_id'],
      'type': row['type'],
      'available_at': row['available_at'],
    }, card, srs);
  }

  // Optimized: getAllWordExercices (single JOIN, uses fromMap)
  Future<List<WordExercice>> getAllWordExercices() async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT
        e.id    AS exo_id,
        e.type  AS exo_type,
        e.available_at AS exo_available_at,

        w.card_id AS card_id,

        c.id AS card_id_real,
        c.note_id AS card_note_id,
        c.template_id AS card_template_id,

        n.id   AS note_id_real,
        n.data AS note_data,
        n.tags AS note_tags,
        n.created_time AS note_created_time,

        t.id AS template_id_real,
        t.recto_html AS recto_html,
        t.verso_html AS verso_html,

        s.next_review AS next_review,
        s.ease_factor AS ease_factor,
        s.interval AS interval,
        s.k_factor AS k_factor,
        s.w AS w,
        s.rbar AS rbar,
        s.last_review AS last_review,
        s.learning_step_index AS learning_step_index,
        s.history AS history
      FROM exercices e
      JOIN word_exercices w ON e.id = w.id
      JOIN cards c ON w.card_id = c.id
      JOIN notes n ON c.note_id = n.id
      JOIN card_templates t ON c.template_id = t.id
      JOIN srs_states s ON s.exercice_id = e.id
      WHERE e.type = 'word'
    ''');

    final List<WordExercice> out = [];

    for (final row in rows) {
      // build minimal maps expected by fromMap (no manual casting)
      final noteMap = {
        'id': row['note_id_real'],
        'data': row['note_data'],
        'tags': row['note_tags'],
        'created_time': row['note_created_time'],
      };
      final note = Note.fromMap(noteMap);

      final templateMap = {
        'id': row['template_id_real'],
        'recto_html': row['recto_html'],
        'verso_html': row['verso_html'],
      };
      final template = CardTemplate.fromMap(templateMap);

      final card = Card.fromMap({'id': row['card_id_real']}, note, template);

      final srsMap = {
        'next_review': row['next_review'],
        'ease_factor': row['ease_factor'],
        'interval': row['interval'],
        'k_factor': row['k_factor'],
        'w': row['w'],
        'rbar': row['rbar'],
        'last_review': row['last_review'],
        'learning_step_index': row['learning_step_index'],
        'history': row['history'],
      };
      final srs = SRSState.fromMap(srsMap);

      final exoMap = {
        'id': row['exo_id'],
        'available_at': row['exo_available_at'],
        'type': row['exo_type'],
      };

      out.add(WordExercice.fromMap(exoMap, card, srs));
    }

    return out;
  }

  // Optimized: getDueExercices (only due ones, single JOIN)
  Future<List<WordExercice>> getDueExercices() async {
    final db = await database;
    final iso = toIsoUtc(DateTime.now().toUtc());

    final rows = await db.rawQuery('''
      SELECT
        e.id    AS exo_id,
        e.type  AS exo_type,
        e.available_at AS exo_available_at,

        w.card_id AS card_id,

        c.id AS card_id_real,
        c.note_id AS card_note_id,
        c.template_id AS card_template_id,

        n.id   AS note_id_real,
        n.data AS note_data,
        n.tags AS note_tags,
        n.created_time AS note_created_time,

        t.id AS template_id_real,
        t.recto_html AS recto_html,
        t.verso_html AS verso_html,

        s.next_review AS next_review,
        s.ease_factor AS ease_factor,
        s.interval AS interval,
        s.k_factor AS k_factor,
        s.w AS w,
        s.rbar AS rbar,
        s.last_review AS last_review,
        s.learning_step_index AS learning_step_index,
        s.history AS history
      FROM exercices e
      JOIN word_exercices w ON e.id = w.id
      JOIN cards c ON w.card_id = c.id
      JOIN notes n ON c.note_id = n.id
      JOIN card_templates t ON c.template_id = t.id
      JOIN srs_states s ON s.exercice_id = e.id
      WHERE e.type = 'word'
        AND (e.available_at <= ? OR s.next_review <= ?)
    ''', [iso, iso]);

    final List<WordExercice> out = [];
    for (final row in rows) {
      final note = Note.fromMap({
        'id': row['note_id_real'],
        'data': row['note_data'],
        'tags': row['note_tags'],
        'created_time': row['note_created_time'],
      });

      final template = CardTemplate.fromMap({
        'id': row['template_id_real'],
        'recto_html': row['recto_html'],
        'verso_html': row['verso_html'],
      });

      final card = Card.fromMap({'id': row['card_id_real']}, note, template);

      final srs = SRSState.fromMap({
        'next_review': row['next_review'],
        'ease_factor': row['ease_factor'],
        'interval': row['interval'],
        'k_factor': row['k_factor'],
        'w': row['w'],
        'rbar': row['rbar'],
        'last_review': row['last_review'],
        'learning_step_index': row['learning_step_index'],
        'history': row['history'],
      });

      out.add(WordExercice.fromMap({
        'id': row['exo_id'],
        'available_at': row['exo_available_at'],
        'type': row['exo_type'],
      }, card, srs));
    }

    return out;
  }

  // GET some new exercices
  Future<List<WordExercice>> getNewExercices(int limit) async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT
        e.id    AS exo_id,
        e.type  AS exo_type,
        e.available_at AS exo_available_at,

        w.card_id AS card_id,

        c.id AS card_id_real,
        c.note_id AS card_note_id,
        c.template_id AS card_template_id,

        n.id   AS note_id_real,
        n.data AS note_data,
        n.tags AS note_tags,
        n.created_time AS note_created_time,

        t.id AS template_id_real,
        t.recto_html AS recto_html,
        t.verso_html AS verso_html,

        s.next_review AS next_review,
        s.ease_factor AS ease_factor,
        s.interval AS interval,
        s.k_factor AS k_factor,
        s.w AS w,
        s.rbar AS rbar,
        s.last_review AS last_review,
        s.learning_step_index AS learning_step_index,
        s.history AS history
      FROM exercices e
      JOIN word_exercices w ON e.id = w.id
      JOIN cards c ON w.card_id = c.id
      JOIN notes n ON c.note_id = n.id
      JOIN card_templates t ON c.template_id = t.id
      JOIN srs_states s ON s.exercice_id = e.id
      WHERE e.available_at IS NULL
      ORDER BY e.id ASC
    ''');

    final List<WordExercice> out = [];
    for (int i = 0; i < rows.length && i < limit; i++) {
      final row = rows[i];
      final note = Note.fromMap({
        'id': row['note_id_real'],
        'data': row['note_data'],
        'tags': row['note_tags'],
        'created_time': row['note_created_time'],
      });

      final template = CardTemplate.fromMap({
        'id': row['template_id_real'],
        'recto_html': row['recto_html'],
        'verso_html': row['verso_html'],
      });

      final card = Card.fromMap({'id': row['card_id_real']}, note, template);

      final srs = SRSState.fromMap({
        'next_review': row['next_review'],
        'ease_factor': row['ease_factor'],
        'interval': row['interval'],
        'k_factor': row['k_factor'],
        'w': row['w'],
        'rbar': row['rbar'],
        'last_review': row['last_review'],
        'learning_step_index': row['learning_step_index'],
        'history': row['history'],
      });

      out.add(WordExercice.fromMap({
        'id': row['exo_id'],
        'available_at': row['exo_available_at'],
        'type': row['exo_type'],
      }, card, srs));
    }

    return out;
  }

  // UPDATE
  Future<int> updateWordExercice(WordExercice exo) async {
    final db = await database;
    await updateSrsState(exo.srsData, exo.id!);
    
    return await db.update(
      'exercices',
      {
        'available_at': toIsoUtc(exo.availableAt),
        'type': exerciceTypeToText(exo.type),
      },
      where: 'id = ?',
      whereArgs: [exo.id],
    );
  }

  // DELETE
  Future<int> deleteWordExercice(int id) async {
    final db = await database;
    // Suppression en cascade via clé étrangère
    return await db.delete(
      'exercices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ---------- SRS_STATES ----------

  // INSERT
  Future<void> insertSrsState(SRSState s, int exerciceId) async {
    final db = await database;
    await db.insert(
      'srs_states',
      s.toMap(exerciceId),
      conflictAlgorithm: ConflictAlgorithm.replace, // en cas de doublon
    );
  }
  
  // GET by ID
  Future<SRSState?> getSrsStateByExerciceId(int exerciceId) async {
    final db = await database;
    final result = await db.query(
      'srs_states',
      where: 'exercice_id = ?',
      whereArgs: [exerciceId],
    );
    if (result.isEmpty) return null;
    return SRSState.fromMap(result.first);
  }

  // UPDATE
  Future<int> updateSrsState(SRSState s, int exerciceId) async {
    final db = await database;
    return await db.update(
      'srs_states',
      s.toMap(exerciceId),
      where: 'exercice_id = ?',
      whereArgs: [exerciceId],
    );
  }
  
  // DELETE
  Future<int> deleteSrsState(int exerciceId) async {
    final db = await database;
    return await db.delete(
      'srs_states',
      where: 'exercice_id = ?',
      whereArgs: [exerciceId],
    );
  }


  // ---------- SRS_CONFIGS ----------

  // INSERT
  Future<int> insertSrsConfig(SRSConfig config) async {
    final db = await database;
    return await db.insert(
      'srs_configs',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET by ID
  Future<SRSConfig?> getSrsConfigById(int id) async {
    final db = await database;
    final result = await db.query(
      'srs_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return SRSConfig.fromMap(result.first);
  }

  // GET all
  Future<List<SRSConfig>> getAllSrsConfigs() async {
    final db = await database;
    final result = await db.query('srs_configs');
    return result.map((row) => SRSConfig.fromMap(row)).toList();
  }

  // UPDATE
  Future<int> updateSrsConfig(SRSConfig config) async {
    final db = await database;
    return await db.update(
      'srs_configs',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  // DELETE
  Future<int> deleteSrsConfig(int id) async {
    final db = await database;
    return await db.delete(
      'srs_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ---------- CLOSE ----------
  Future close() async {
    final db = await database;
    await db.close();
  }
}
