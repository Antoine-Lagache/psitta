import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/domain/history/exercise_history_entry.dart';

import 'package:psitta/infrastructure/persistence/dao/exercise_history_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise_history_mapper.dart';

import 'package:psitta/utils/conversion/time_conversion.dart';

/// Exposes persisted answer history as domain entries.
class ExerciseHistoryRepository {
  final sqlite.SqliteDatabase database;

  final ExerciseHistoryDao _historyDao;

  ExerciseHistoryRepository(this.database) : _historyDao = ExerciseHistoryDao(database);

  /// Returns entries in a half-open date range, optionally for one exercise.
  Future<List<ExerciseHistoryEntry>> getList({
    int? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final list = await _historyDao.getList(
      exerciseId: exerciseId,
      startDate: toIsoUtc(startDate),
      endDate: toIsoUtc(endDate),
    );
    return list
        .map((persistence) => ExerciseHistoryMapper.toDomain(persistence))
        .toList();
  }
}
