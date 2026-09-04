import 'dart:io';

import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:psitta/infrastructure/persistence/database/psitta_sqlite_open_factory.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/sentence_group_repository.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';

void main() {
  late Directory temporaryDirectory;
  late sqlite.SqliteDatabase database;
  late ExerciseRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('psitta_test_');

    database = sqlite.SqliteDatabase.withFactory(
      PsittaSqliteOpenFactory(path: '${temporaryDirectory.path}/test.db'),
    );

    await database.initialize();
    await createMigrationRunner().migrate(database);

    repository = ExerciseRepository(database);
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  group('ExerciseRepository', () {
    test('enables foreign-key enforcement', () async {
      final foreignKeysEnabled = await database.writeTransaction(
        (transaction) async {
          final result = await transaction.getAll('PRAGMA foreign_keys');
          return result.single['foreign_keys'];
        },
      );

      expect(foreignKeysEnabled, 1);
    });

    test('createWordExercise creates and returns an exercise id', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);

      expect(exerciseId, greaterThan(0));

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isA<WordExercise>());
      expect(exercise!.id, exerciseId);
    });

    test('createSentenceExercise rejects an empty sentence group', () async {
      await database.execute('INSERT INTO sentence_group (id) VALUES (1)');

      await expectLater(
        repository.createSentenceExercise(1, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createSentenceExercise creates and returns an exercise id', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');
      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      await sentenceGroupRepository.createInstance(sentenceGroupId, 1);

      final exerciseId = await repository.createSentenceExercise(sentenceGroupId, 1);

      expect(exerciseId, greaterThan(0));

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isA<SentenceExercise>());
      expect(exercise!.id, exerciseId);
    });

    test('prevents deleting a sentence group used by an exercise', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');
      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      await sentenceGroupRepository.createInstance(sentenceGroupId, 1);
      final exerciseId = await repository.createSentenceExercise(sentenceGroupId, 1);

      await expectLater(
        sentenceGroupRepository.deleteSentenceGroup(sentenceGroupId),
        throwsA(anything),
      );

      expect(await repository.getById(exerciseId), isA<SentenceExercise>());
    });

    test('getById returns null for an unknown exercise', () async {
      final exercise = await repository.getById(999);

      expect(exercise, isNull);
    });

    test('getNewExercises returns newly created exercises', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);

      final exercises = await repository.getNewExercises(10, 'word');

      expect(exercises, hasLength(1));
      expect(exercises.first.id, exerciseId);
      expect(exercises.first, isA<WordExercise>());
    });

    test('getDueExercises returns due exercises', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);

      // Make the exercise due.
      await database.execute(
        '''
        UPDATE srs_state
        SET next_review = 0
        WHERE exercise_id = ?
        ''',
        [exerciseId],
      );

      final exercises = await repository.getDueExercises(DateTime.now(), 10, 'word');

      expect(exercises, hasLength(1));
      expect(exercises.first.id, exerciseId);
    });

    test('save executes successfully for an existing exercise', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);
      final exercise = await repository.getById(exerciseId);

      expect(exercise, isNotNull);

      exercise!.srsState = SRSState(learningStepIndex: -1);
      await repository.save(exercise!);

      final savedExercise = await repository.getById(exerciseId);

      expect(savedExercise, isNotNull);
      expect(savedExercise!.id, exerciseId);
      expect(savedExercise.srsState.learningStepIndex, -1);
    });

    test('answer persistence rolls back when the session update fails', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');
      final exerciseId = await repository.createWordExercise(1);
      final exercise = (await repository.getById(exerciseId))!;
      final sessionRepository = SessionRepository(
        database,
        exerciseRepository: repository,
      );
      final session = Session(
        exercises: [exercise],
        sessionType: SessionType.wordSession,
        config: SRSConfig(),
      );
      final answeredAt = DateTime(2026, 9, 4, 12);

      session.beginSession(answeredAt);
      session.intermediateResult.id = await sessionRepository.save(session);
      final answeredExercise = session.currentExercise;
      session.submitAnswer(
        SubmittedExerciseAnswer(grade: Grade.again, answeredAt: answeredAt),
      );

      session.intermediateResult.id = -1;
      await expectLater(
        sessionRepository.saveAnswerProgress(session, answeredExercise),
        throwsA(anything),
      );

      final persistedExercise = await repository.getById(exerciseId);
      expect(persistedExercise!.srsState.lastReview, isNull);
      expect(answeredExercise.newHistoryEntry, hasLength(1));
    });

    test('delete removes an exercise', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);

      await repository.delete(exerciseId);

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isNull);
    });

    test('resetProgress resets an exercise', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);

      final exercise = await repository.getById(exerciseId);
      expect(exercise, isNotNull);

      await repository.resetProgress(exerciseId);

      final resetExercise = await repository.getById(exerciseId);

      expect(resetExercise, isNotNull);
      expect(resetExercise!.id, exerciseId);
    });
  });
}
