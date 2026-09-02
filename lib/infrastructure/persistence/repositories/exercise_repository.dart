import 'package:psitta/infrastructure/persistence/mappers/exercise/word_exercise_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/domain/exercise/exercise.dart';

import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_history_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';

import 'package:psitta/infrastructure/persistence/mappers/exercise_history_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/sentence_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_mapper.dart';

import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';

class ExerciseRepository {
  final sqlite.SqliteDatabase database;

  final ExerciseDao _exerciseDao;
  final ExerciseHistoryDao _historyDao;
  final SentenceGroupDao _sentencesDao;

  ExerciseRepository(this.database)
    : _exerciseDao = ExerciseDao(database),
      _historyDao = ExerciseHistoryDao(database),
      _sentencesDao = SentenceGroupDao(database);

  Future<int> createWordExercise(int contentId) async {
    return await _exerciseDao.insert(WordExerciseMapper.newWordExercise(contentId));
  }

  Future<int> createSentenceExercise(int sentenceGroupId, int trainingCount) async {
    return await _exerciseDao.insert(
      SentenceExerciseMapper.newSentenceExercise(sentenceGroupId, trainingCount),
    );
  }

  Future<Exercise?> getById(int id) async {
    final ExercisePersistence? persistence = await _exerciseDao.getById(id);

    if (persistence == null) return null;

    final hasHistory = await _historyDao.hasHistory(persistence.id!);

    return _toDomain(persistence, hasHistory);
  }

  Future<List<Exercise>> getDueExercises(DateTime now, int count, String? type) async {
    final persistenceExercises = await _exerciseDao.getDueExercises(
      now.microsecondsSinceEpoch,
      count,
      type,
    );

    final exercises = <Exercise>[];

    for (final persistence in persistenceExercises) {
      final hasHistory = await _historyDao.hasHistory(persistence.id!);
      exercises.add(await _toDomain(persistence, hasHistory));
    }

    return exercises;
  }

  Future<List<Exercise>> getNewExercises(int count, String? type) async {
    final persistenceExercises = await _exerciseDao.getNewExercises(count, type);

    final exercises = <Exercise>[];

    for (final persistence in persistenceExercises) {
      exercises.add(await _toDomain(persistence, false));
    }

    return exercises;
  }

  Future<void> save(Exercise exercise) async {
    await database.writeTransaction((txn) => saveInTransaction(txn, exercise));
    exercise.clearNewHistoryEntries();
  }

  Future<void> saveInTransaction(
    sqlite.SqliteWriteContext txn,
    Exercise exercise,
  ) async {
    ExercisePersistence persistence;
    switch (exercise) {
      case WordExercise word:
        persistence = WordExerciseMapper.wordToPersistence(word);
        break;
      case SentenceExercise sentence:
        persistence = SentenceExerciseMapper.sentenceToPersistence(sentence);
        SentenceGroupPersistence group = SentenceMapper.toPersistence(
          sentence.sentences,
        );
        await _sentencesDao.updateSentencesState(txn, group);
        break;
      default:
        throw StateError("Unknown Exercise type");
    }

    if (persistence.id == null) {
      throw ArgumentError("Cannot update an entity that doesn't have an id");
    }

    await _exerciseDao.updateSrsState(txn, persistence.id!, persistence.srsState);

    await _historyDao.insertAll(
      txn,
      exercise.newHistoryEntry
          .map((entry) => ExerciseHistoryMapper.toPersistence(entry))
          .toList(),
    );
  }

  Future<void> delete(int exerciseId) async {
    await _exerciseDao.delete(exerciseId);
  }

  Future<void> resetProgress(int exerciseId) async {
    final exercise = await _exerciseDao.getById(exerciseId);
    if (exercise == null) {
      throw StateError("Missing Exercise with id $exerciseId");
    }
    await database.writeTransaction((txn) async {
      ExercisePersistence resetExercise;
      switch (exercise) {
        case WordExercisePersistence word:
          resetExercise = WordExerciseMapper.newWordExercise(
            word.contentId,
            id: exerciseId,
          );
          break;
        case SentenceExercisePersistence sentence:
          resetExercise = SentenceExerciseMapper.newSentenceExercise(
            sentence.sentenceGroupId,
            sentence.trainingCountMax,
            id: exerciseId,
          );
          final group = await _sentencesDao.getById(sentence.sentenceGroupId);
          if (group == null) {
            throw StateError("Missing SentenceGroup for sentenceExercise");
          }
          await _sentencesDao.update(txn, SentenceMapper.resetGroupProgress(group));
          break;
      }

      await _historyDao.deleteAll(txn, exerciseId);
      await _exerciseDao.update(txn, resetExercise);
    });
  }

  Future<Exercise> _toDomain(ExercisePersistence persistence, bool hasHistory) async {
    switch (persistence) {
      case WordExercisePersistence word:
        return WordExerciseMapper.wordToDomain(word, hasHistory);

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

        return SentenceExerciseMapper.sentenceToDomain(sentence, hasHistory, sentences);
    }
  }
}
