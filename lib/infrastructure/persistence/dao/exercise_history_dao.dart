import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:psitta/infrastructure/persistence/models/exercise_history_persistence.dart';

class ExerciseHistoryDao {
  final sqlite.SqliteDatabase database;

  ExerciseHistoryDao(this.database);

  /// Return the id of the new inserted exercise history
  Future<int> insert(ExerciseHistoryPersistence history) {
    if (history.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final result = await txn.execute(
        '''
        INSERT INTO exercise_history (
          exercise_id,
          grade,
          answered_at
        )
        VALUES (?, ?, ?)
        RETURNING id
        ''',
        [history.exerciseId, history.grade, toIsoUtc(history.answeredAt)],
      );

      return result.first['id'] as int;
    });
  }

  Future<ExerciseHistoryPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final rows = await txn.getAll(
        '''
        SELECT
          id,
          exercise_id,
          grade,
          answered_at
        FROM exercise_history
        WHERE id = ?
        ''',
        [id],
      );

      if (rows.isEmpty) {
        return null;
      }

      return ExerciseHistoryPersistence.fromRow(rows.first);
    });
  }

  Future<List<ExerciseHistoryPersistence>> getByExerciseId(int exerciseId) {
    return database.readTransaction((txn) async {
      final rows = await txn.getAll(
        '''
        SELECT
          id,
          exercise_id,
          grade,
          answered_at
        FROM exercise_history
        WHERE exercise_id = ?
        ORDER BY answered_at DESC
        ''',
        [exerciseId],
      );

      return rows.map(ExerciseHistoryPersistence.fromRow).toList();
    });
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM exercise_history
        WHERE id = ?
        ''',
        [id],
      );
    });
  }
}
