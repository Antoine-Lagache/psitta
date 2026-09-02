import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/session_exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/session/session_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/dao/session_result_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/session/session_result_mapper.dart';

import 'package:psitta/utils/conversion/time_conversion.dart';

class SessionRepository {
  final sqlite.SqliteDatabase database;

  final SessionResultDao _sessionResultDao;
  final SessionExerciseDao _sessionExerciseDao;
  final ExerciseDao _exerciseDao;
  final SentenceGroupDao _sentencesDao;

  SessionRepository(this.database)
    : _sessionResultDao = SessionResultDao(database),
      _sessionExerciseDao = SessionExerciseDao(database),
      _exerciseDao = ExerciseDao(database),
      _sentencesDao = SentenceGroupDao(database);

  Future<int> save(Session session) async {
    return database.writeTransaction((txn) async {
      final sessionResultPersistence = SessionResultMapper.toPersistence(
        session.intermediateResult,
      );

      final sessionResultId = await _sessionResultDao.insert(
        sessionResultPersistence,
        txn,
      );

      final exerciseResumes = session
          .getResumeList()
          .map(SessionExerciseMapper.toPersistence)
          .toList();

      await _sessionExerciseDao.insertAll(sessionResultId, exerciseResumes, txn);

      return sessionResultId;
    });
  }

  Future<List<SessionResult>> getAllActiveSessionResult() async {
    final activeSessionId = await _sessionExerciseDao.getAllSessionId();

    final allSessionResult = <SessionResult>[];

    for (final sessionId in activeSessionId) {
      final sessionResult = await _sessionResultDao.getById(sessionId);

      final sessionResultDomain = SessionResultMapper.toDomain(sessionResult!);
      allSessionResult.add(sessionResultDomain);
    }
    return allSessionResult;
  }

  Future<Session> getActiveSession(SessionResult sessionResult, SRSConfig config) async {
    final sessionResultId = sessionResult.id!;

    final sessionExercisesPercistence = await _sessionExerciseDao.getAll(sessionResultId);
    final sessionExercisesDomain = sessionExercisesPercistence
        .map(SessionExerciseMapper.toDomain)
        .toList();

    final List<Exercise> exercises = [];
    for (final ExerciseResume sessionExercise in sessionExercisesDomain) {
      final exercisePersistence = await _exerciseDao.getById(sessionExercise.exerciseId);
      exercises.add(await _toDomain(exercisePersistence!, sessionExercise));
    }
    return Session(
      exercises: exercises,
      sessionType: sessionResult.sessionType,
      config: config,
      existingSessionResult: sessionResult,
    )..resumeSession(DateTime.now());
  }

  Future<Exercise> _toDomain(
    ExercisePersistence persistence,
    ExerciseResume resume,
  ) async {
    switch (persistence) {
      case WordExercisePersistence word:
        return WordExercise(
          contentId: word.contentId,
          id: word.id!,
          status: resume.status,
          srsState: SRSStateMapper.toDomainSrsState(word.srsState),
        );

      case SentenceExercisePersistence sentence:
        final sentencesPersistence = await _sentencesDao.getById(
          sentence.sentenceGroupId,
        );

        if (sentencesPersistence == null) {
          throw StateError(
            'Missing sentence group ${sentence.sentenceGroupId} '
            'for exercise ${sentence.id}',
          );
        }

        final sentences = SentenceMapper.toDomain(sentencesPersistence);

        return SentenceExercise(
          sentences: sentences,
          trainingCountMax: sentence.trainingCountMax,
          trainingCount: resume.trainingCount!,
          id: sentence.id!,
          status: resume.status,
          srsState: SRSStateMapper.toDomainSrsState(sentence.srsState),
        );
    }
  }

  Future<void> update(Session session) async {
    final sessionResult = session.intermediateResult;

    if (sessionResult.id == null) {
      throw ArgumentError('Cannot update a Session whose SessionResult has no id');
    }

    final sessionResultId = sessionResult.id!;

    await database.writeTransaction((txn) => updateInTransaction(txn, session));
  }

  Future<void> updateInTransaction(
    sqlite.SqliteWriteContext txn,
    Session session,
  ) async {
    final sessionResult = session.intermediateResult;
    if (sessionResult.id == null) {
      throw ArgumentError('Cannot update a Session whose SessionResult has no id');
    }
    final sessionResultId = sessionResult.id!;
    final sessionResultPersistence = SessionResultMapper.toPersistence(sessionResult);

    await _sessionResultDao.update(sessionResultPersistence, txn);

    final exerciseResumes = session
        .getResumeList()
        .map(SessionExerciseMapper.toPersistence)
        .toList();

    await _sessionExerciseDao.deleteAll(sessionResultId, txn);

    await _sessionExerciseDao.insertAll(sessionResultId, exerciseResumes, txn);
  }

  Future<void> deleteSessionResult(int sessionResultId) {
    return _sessionResultDao.delete(sessionResultId);
  }

  Future<void> completeSession(Session session) {
    final sessionResult = session.intermediateResult;
    if (sessionResult.id == null) {
      throw ArgumentError('Cannot update a Session whose SessionResult has no id');
    }

    final sessionResultId = sessionResult.id!;

    return database.writeTransaction((txn) async {
      final sessionResultPersistence = SessionResultMapper.toPersistence(sessionResult);

      await _sessionResultDao.update(sessionResultPersistence, txn);

      return _sessionExerciseDao.deleteAll(sessionResultId, txn);
    });
  }

  Future<void> completeSessionInTransaction(
    sqlite.SqliteWriteContext txn,
    Session session,
  ) async {
    final sessionResult = session.intermediateResult;
    if (sessionResult.id == null) {
      throw ArgumentError('Cannot update a Session whose SessionResult has no id');
    }
    await _sessionResultDao.update(SessionResultMapper.toPersistence(sessionResult), txn);
    await _sessionExerciseDao.deleteAll(sessionResult.id!, txn);
  }

  Future<List<SessionResult>> getList({DateTime? startedDate, DateTime? endDate}) async {
    final persistenceList = await _sessionResultDao.getList(
      startDate: toIsoUtc(startedDate),
      endDate: toIsoUtc(endDate),
    );

    return persistenceList.map(SessionResultMapper.toDomain).toList();
  }
}
