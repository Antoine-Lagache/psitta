import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/domain/exercise/exercise.dart';

import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_history_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';

import 'package:psitta/infrastructure/persistence/mappers/exercise_history_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_mapper.dart';

import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';

class ExerciseRepository {
  final sqlite.SqliteDatabase database;

  final ExerciseDao exerciseDao;
  final ExerciseHistoryDao historyDao;
  final SentenceGroupDao sentencesDao;

  ExerciseRepository(this.database)
    : exerciseDao = ExerciseDao(database),
      historyDao = ExerciseHistoryDao(database),
      sentencesDao = SentenceGroupDao(database);

  Future<int> createWordExercise(int contentId) async {
    return await exerciseDao.insert(ExerciseMapper.newWordExercise(contentId));
  }

  Future<int> createSentenceExercise(int sentenceGroupId, int trainingCount) async {
    return await exerciseDao.insert(
      ExerciseMapper.newSentenceExercise(sentenceGroupId, trainingCount),
    );
  }

  Future<Exercise?> getById(int id) async {
    final ExercisePersistence? persistence = await exerciseDao.getById(id);

    if (persistence == null) return null;

    final hasHistory = await historyDao.hasHistory(persistence.id!);

    return _toDomain(persistence, hasHistory);
  }

  Future<List<Exercise>> getDueExercises(DateTime now, int count, String? type) async {
    final persistenceExercises = await exerciseDao.getDueExercises(
      now.microsecondsSinceEpoch,
      count,
      type,
    );

    final exercises = <Exercise>[];

    for (final persistence in persistenceExercises) {
      final hasHistory = await historyDao.hasHistory(persistence.id!);
      exercises.add(await _toDomain(persistence, hasHistory));
    }

    return exercises;
  }

  Future<List<Exercise>> getNewExercises(int count, String? type) async {
    final persistenceExercises = await exerciseDao.getNewExercises(count, type);

    final exercises = <Exercise>[];

    for (final persistence in persistenceExercises) {
      exercises.add(await _toDomain(persistence, false));
    }

    return exercises;
  }

  Future<void> save(Exercise exercise) async {
    return database.writeTransaction((txn) async {
      ExercisePersistence persistence;
      switch (exercise) {
        case WordExercise word:
          persistence = ExerciseMapper.wordToPersistence(word);
          break;
        case SentenceExercise sentence:
          persistence = ExerciseMapper.sentenceToPersistence(sentence);
          SentenceGroupPersistence group = SentenceMapper.toPersistence(
            sentence.sentences,
          );
          await sentencesDao.updateSentencesState(txn, group);
          break;
        default:
          throw StateError("Unknown Exercise type");
      }

      if (persistence.id == null) {
        throw ArgumentError("Cannot update an entity that doesn't have an id");
      }

      await exerciseDao.updateSrsState(txn, persistence.id!, persistence.srsState);

      await historyDao.insertAll(
        txn,
        exercise.newHistoryEntry
            .map((entry) => ExerciseHistoryMapper.toPersistence(entry))
            .toList(),
      );
    });
  }

  Future<void> delete(int exerciseId) async {
    await exerciseDao.delete(exerciseId);
  }

  Future<void> resetProgress(int exerciseId) async {
    final exercise = await exerciseDao.getById(exerciseId);
    if (exercise == null) {
      throw StateError("Missing Exercise with id $exerciseId");
    }
    await database.writeTransaction((txn) async {
      ExercisePersistence resetExercise;
      switch (exercise) {
        case WordExercisePersistence word:
          resetExercise = ExerciseMapper.newWordExercise(word.contentId, id: exerciseId);
          break;
        case SentenceExercisePersistence sentence:
          resetExercise = ExerciseMapper.newSentenceExercise(
            sentence.sentenceGroupId,
            sentence.trainingCountMax,
            id: exerciseId,
          );
          final group = await sentencesDao.getById(sentence.sentenceGroupId);
          if (group == null) {
            throw StateError("Missing SentenceGroup for sentenceExercise");
          }
          await sentencesDao.update(txn, SentenceMapper.resetGroupProgress(group));
          break;
      }

      await historyDao.deleteAll(txn, exerciseId);
      await exerciseDao.update(txn, resetExercise);
    });
  }

  Future<Exercise> _toDomain(ExercisePersistence persistence, bool hasHistory) async {
    switch (persistence) {
      case WordExercisePersistence word:
        return ExerciseMapper.wordToDomain(word, hasHistory);

      case SentenceExercisePersistence sentence:
        final sentencesPersistence = await sentencesDao.getById(sentence.sentenceGroupId);

        if (sentencesPersistence == null) {
          throw StateError(
            'Missing sentence group ${sentence.sentenceGroupId} '
            'for exercise ${sentence.id}',
          );
        }

        final sentences = SentenceMapper.toDomain(sentencesPersistence);

        return ExerciseMapper.sentenceToDomain(sentence, hasHistory, sentences);
    }
  }
}
