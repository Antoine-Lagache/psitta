import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';

class SentenceGroupRepository {
  final sqlite.SqliteDatabase database;

  final SentenceGroupDao sentencesDao;

  SentenceGroupRepository(this.database) : sentencesDao = SentenceGroupDao(database);

  Future<int> createGroup() async {
    final sentenceGroup = SentenceGroupPersistence(sentenceInstances: []);
    return await sentencesDao.insertSentenceGroup(sentenceGroup);
  }

  Future<int> createInstance(int sentenceGroupId, int contentId) async {
    final sentenceGroup = await sentencesDao.getById(sentenceGroupId);
    if (sentenceGroup == null) {
      throw StateError("Missing SentenceGroup with id $sentenceGroupId");
    }

    final SentenceInstancePersistence newInstance = SentenceMapper.newInstance(contentId);
    return await sentencesDao.insertSentenceInstance(newInstance, sentenceGroupId);
  }

  Future<void> moveSentenceInstance(int sentenceInstanceId, int targetGroupId) async {
    final sentenceGroup = await sentencesDao.getById(targetGroupId);
    if (sentenceGroup == null) {
      throw StateError("Missing SentenceGroup with id $targetGroupId");
    }
    await sentencesDao.moveSentenceInstance(sentenceInstanceId, targetGroupId);
  }

  Future<void> deleteSentenceGroup(int sentenceGroupId) async {
    await sentencesDao.delete(sentenceGroupId);
  }

  Future<void> deleteSentenceInstance(int sentenceInstanceId) async {
    await sentencesDao.deleteSentenceInstance(sentenceInstanceId);
  }
}
