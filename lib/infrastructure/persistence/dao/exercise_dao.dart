import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import "package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart";

/// Stores exercise base rows, subtype rows, and their SRS state.
class ExerciseDao {
  final sqlite.SqliteDatabase database;

  ExerciseDao(this.database);

  // Public operations

  Future<int> insert(ExercisePersistence exercise) {
    if (exercise.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final exerciseId = await _insertExercise(txn, exercise);

      await _insertSrsState(txn, exerciseId, exercise.srsState);

      switch (exercise) {
        case WordExercisePersistence():
          await _insertWordExercise(txn, exerciseId, exercise);

        case SentenceExercisePersistence():
          await _insertSentenceExercise(txn, exerciseId, exercise);
      }

      return exerciseId;
    });
  }

  Future<ExercisePersistence?> getById(int id) {
    return database.readTransaction((txn) => _getExercise(txn, id));
  }

  /// Returns due exercises ordered by review time, optionally filtered by type.
  Future<List<ExercisePersistence>> getDueExercises(
    int nowInMicroseconds,
    int count,
    String? type,
  ) {
    return database.readTransaction((txn) async {
      final typeCondition = type == null ? '' : 'AND e.type = ?';

      final arguments = type == null
          ? [nowInMicroseconds, count]
          : [nowInMicroseconds, type, count];

      final exerciseRows = await txn.getAll('''
      SELECT e.id
      FROM exercise e
      JOIN srs_state s ON s.exercise_id = e.id
      WHERE s.next_review IS NOT NULL
        AND s.next_review <= ?
        $typeCondition
      ORDER BY s.next_review ASC
      LIMIT ?
      ''', arguments);

      final exercises = <ExercisePersistence>[];

      for (final row in exerciseRows) {
        final id = row['id'] as int;
        final exercise = await _getExercise(txn, id);

        if (exercise == null) {
          throw StateError('Exercise $id disappeared while retrieving due exercises');
        }

        exercises.add(exercise);
      }

      return exercises;
    });
  }

  /// Returns exercises with no history, optionally filtered by type.
  Future<List<ExercisePersistence>> getNewExercises(int count, String? type) {
    return database.readTransaction((txn) async {
      final typeCondition = type == null ? '' : 'AND e.type = ?';

      final arguments = type == null ? [count] : [type, count];

      final exerciseRows = await txn.getAll('''
        SELECT e.id
        FROM exercise e
        WHERE NOT EXISTS (
          SELECT 1
          FROM exercise_history h
          WHERE h.exercise_id = e.id
        )
        $typeCondition
        ORDER BY e.id ASC
        LIMIT ?
        ''', arguments);

      final exercises = <ExercisePersistence>[];

      for (final row in exerciseRows) {
        final int id = row['id'] as int;
        final exercise = await _getExercise(txn, id);

        if (exercise == null) {
          throw StateError('Exercise $id disappeared while retrieving new exercises');
        }

        exercises.add(exercise);
      }

      return exercises;
    });
  }

  /// Updates an exercise aggregate within the caller's transaction.
  Future<void> update(sqlite.SqliteWriteContext txn, ExercisePersistence exercise) async {
    if (exercise.id == null) {
      throw ArgumentError('Cannot update an exercise without an id');
    }
    final exerciseId = exercise.id!;

    final currentExercise = await _getExerciseRow(txn, exerciseId);
    if (currentExercise == null) {
      throw StateError('Exercise $exerciseId does not exist');
    }

    _checkExerciseType(currentExercise, exercise);

    await _updateExercise(txn, exercise);

    await updateSrsState(txn, exerciseId, exercise.srsState);

    switch (exercise) {
      case WordExercisePersistence():
        await _updateWordExercise(txn, exerciseId, exercise);

      case SentenceExercisePersistence():
        await _updateSentenceExercise(txn, exerciseId, exercise);
    }
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
      DELETE FROM exercise
      WHERE id = ?
      ''',
        [id],
      );
    });
  }

  /// Updates scheduling fields within the caller's transaction.
  Future<void> updateSrsState(
    sqlite.SqliteWriteContext txn,
    int exerciseId,
    SrsStatePersistence srsState,
  ) async {
    await txn.execute(
      '''
    UPDATE srs_state
    SET
      ease_factor = ?,
      interval = ?,
      kfactor = ?,
      w = ?,
      rbar = ?,
      last_review = ?,
      next_review = ?
    WHERE exercise_id = ?
    ''',
      [
        srsState.easeFactor,
        srsState.interval,
        srsState.kFactor,
        srsState.w,
        srsState.rBar,
        srsState.lastReview,
        srsState.nextReview,
        exerciseId,
      ],
    );
  }

  // Private insert operations

  Future<int> _insertExercise(
    sqlite.SqliteWriteContext txn,
    ExercisePersistence exercise,
  ) async {
    final result = await txn.execute(
      '''
    INSERT INTO exercise (
      type
    )
    VALUES (?)
    RETURNING id
    ''',
      [exercise.type],
    );

    return result.first['id'] as int;
  }

  Future<void> _insertSrsState(
    sqlite.SqliteWriteContext txn,
    int exerciseId,
    SrsStatePersistence srsState,
  ) async {
    await txn.execute(
      '''
    INSERT INTO srs_state (
      exercise_id,
      ease_factor,
      interval,
      kfactor,
      w,
      rbar,
      last_review,
      next_review
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        exerciseId,
        srsState.easeFactor,
        srsState.interval,
        srsState.kFactor,
        srsState.w,
        srsState.rBar,
        srsState.lastReview,
        srsState.nextReview,
      ],
    );
  }

  Future<void> _insertWordExercise(
    sqlite.SqliteWriteContext txn,
    int exerciseId,
    WordExercisePersistence wordExercise,
  ) async {
    await txn.execute(
      '''
    INSERT INTO word_exercise (
      exercise_id,
      content_id
    )
    VALUES (?, ?)
    ''',
      [exerciseId, wordExercise.contentId],
    );
  }

  Future<void> _insertSentenceExercise(
    sqlite.SqliteWriteContext txn,
    int exerciseId,
    SentenceExercisePersistence sentenceExercise,
  ) async {
    await txn.execute(
      '''
    INSERT INTO sentence_exercise (
      exercise_id,
      sentence_group_id,
      training_count
    )
    VALUES (?, ?, ?)
    ''',
      [exerciseId, sentenceExercise.sentenceGroupId, sentenceExercise.trainingCountMax],
    );
  }

  // Private read operations

  Future<ExercisePersistence?> _getExercise(sqlite.SqliteReadContext txn, int id) async {
    final exerciseRow = await _getExerciseRow(txn, id);
    if (exerciseRow == null) {
      return null;
    }

    final srsState = await _getSrsState(txn, id);

    switch (exerciseRow['type']) {
      case 'word':
        final wordRow = await _getWordExerciseRow(txn, id);
        if (wordRow == null) {
          throw StateError('Missing word_exercise for exercise $id');
        }
        return WordExercisePersistence.fromRow(exerciseRow, wordRow, srsState);

      case 'sentence':
        final sentenceRow = await _getSentenceExerciseRow(txn, id);
        if (sentenceRow == null) {
          throw StateError('Missing sentence_exercise for exercise $id');
        }
        return SentenceExercisePersistence.fromRow(exerciseRow, sentenceRow, srsState);

      default:
        throw StateError('Unknown exercise type: ${exerciseRow['type']}');
    }
  }

  Future<Map<String, Object?>?> _getExerciseRow(
    sqlite.SqliteReadContext txn,
    int id,
  ) async {
    final rows = await txn.getAll(
      '''
    SELECT
      id,
      type
    FROM exercise
    WHERE id = ?
    ''',
      [id],
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<SrsStatePersistence> _getSrsState(
    sqlite.SqliteReadContext txn,
    int exerciseId,
  ) async {
    final rows = await txn.getAll(
      '''
    SELECT
      ease_factor,
      interval,
      kfactor,
      w,
      rbar,
      last_review,
      next_review
    FROM srs_state
    WHERE exercise_id = ?
    ''',
      [exerciseId],
    );

    if (rows.isEmpty) {
      throw StateError('Missing srs_state for exercise $exerciseId');
    }

    return SrsStatePersistence.fromRow(rows.first);
  }

  Future<Map<String, Object?>?> _getWordExerciseRow(
    sqlite.SqliteReadContext txn,
    int exerciseId,
  ) async {
    final rows = await txn.getAll(
      '''
    SELECT
      content_id
    FROM word_exercise
    WHERE exercise_id = ?
    ''',
      [exerciseId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<Map<String, Object?>?> _getSentenceExerciseRow(
    sqlite.SqliteReadContext txn,
    int exerciseId,
  ) async {
    final rows = await txn.getAll(
      '''
    SELECT
      sentence_group_id,
      training_count
    FROM sentence_exercise
    WHERE exercise_id = ?
    ''',
      [exerciseId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  // Private update operations

  void _checkExerciseType(Map<String, Object?> row, ExercisePersistence exercise) {
    if (row['type'] != exercise.type) {
      throw StateError(
        'Cannot change exercise type '
        'from ${row['type']} to ${exercise.type}',
      );
    }
  }

  /// Reserved for mutable fields shared by all exercise subtypes.
  Future<void> _updateExercise(
    sqlite.SqliteWriteContext txn,
    ExercisePersistence exercise,
  ) async {}

  Future<void> _updateWordExercise(
    sqlite.SqliteWriteContext txn,
    int exerciseId,
    WordExercisePersistence wordExercise,
  ) async {
    await txn.execute(
      '''
    UPDATE word_exercise
    SET
      content_id = ?
    WHERE exercise_id = ?
    ''',
      [wordExercise.contentId, exerciseId],
    );
  }

  Future<void> _updateSentenceExercise(
    sqlite.SqliteWriteContext txn,
    int exerciseId,
    SentenceExercisePersistence sentenceExercise,
  ) async {
    await txn.execute(
      '''
    UPDATE sentence_exercise
    SET
      sentence_group_id = ?,
      training_count = ?
    WHERE exercise_id = ?
    ''',
      [sentenceExercise.sentenceGroupId, sentenceExercise.trainingCountMax, exerciseId],
    );
  }
}
