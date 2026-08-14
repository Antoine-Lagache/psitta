import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/infrastructure/persistence/dao/session_result_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/session_result_mapper.dart';

import 'package:psitta/utils/conversion/time_conversion.dart';

class SessionResultRepository {
  final sqlite.SqliteDatabase database;
  final SessionResultDao sessionResultDao;

  SessionResultRepository(this.database) : sessionResultDao = SessionResultDao(database);

  Future<int> save(SessionResult result) async {
    final persistence = SessionResultMapper.toPersistence(result);
    return sessionResultDao.insert(persistence);
  }

  Future<List<SessionResult>> getList({DateTime? startedDate, DateTime? endDate}) async {
    final list = await sessionResultDao.getList(
      startDate: toIsoUtc(startedDate),
      endDate: toIsoUtc(endDate),
    );
    return list.map((persistence) => SessionResultMapper.toDomain(persistence)).toList();
  }
}
