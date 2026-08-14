import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/domain/history/exercise_history_entry.dart';

import 'package:psitta/infrastructure/persistence/dao/exercise_history_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise_history_mapper.dart';

import 'package:psitta/utils/conversion/time_conversion.dart';

class ExerciseHistoryRepository {
  final sqlite.SqliteDatabase database;

  final ExerciseHistoryDao historyDao;

  ExerciseHistoryRepository(this.database) : historyDao = ExerciseHistoryDao(database);

  Future<List<ExerciseHistoryEntry>> getList({
    int? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final list = await historyDao.getList(
      exerciseId: exerciseId,
      startDate: toIsoUtc(startDate),
      endDate: toIsoUtc(endDate),
    );
    return list
        .map((persistence) => ExerciseHistoryMapper.toDomain(persistence))
        .toList();
  }
}
