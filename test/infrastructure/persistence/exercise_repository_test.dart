import 'dart:io';

import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';

void main() {
  late Directory temporaryDirectory;
  late sqlite.SqliteDatabase database;
  late ExerciseRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('psitta_test_');

    database = sqlite.SqliteDatabase(path: '${temporaryDirectory.path}/test.db');

    await createMigrationRunner().migrate(database);

    repository = ExerciseRepository(database);
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  group('ExerciseRepository', () {
    test('createWordExercise creates and returns an exercise id', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');

      final exerciseId = await repository.createWordExercise(1);

      expect(exerciseId, greaterThan(0));

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isA<WordExercise>());
      expect(exercise!.id, exerciseId);
    });

    test('createSentenceExercise creates and returns an exercise id', () async {
      await database.execute('INSERT INTO sentence_group (id) VALUES (1)');

      final exerciseId = await repository.createSentenceExercise(1, 0);

      expect(exerciseId, greaterThan(0));

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isA<SentenceExercise>());
      expect(exercise!.id, exerciseId);
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

      await repository.save(exercise!);

      final savedExercise = await repository.getById(exerciseId);

      expect(savedExercise, isNotNull);
      expect(savedExercise!.id, exerciseId);
    });

    test('save persists the full SRS state and history once', () async {
      await database.execute('INSERT INTO content (id) VALUES (1)');
      final exerciseId = await repository.createWordExercise(1);
      final exercise = await repository.getById(exerciseId);
      final answeredAt = DateTime.utc(2026, 9, 2, 12);

      exercise!.applyAnswer(
        SubmittedExerciseAnswer(grade: Grade.easy, answeredAt: answeredAt),
        SRSConfig(),
      );
      await repository.save(exercise);
      await repository.save(exercise);

      final reloaded = await repository.getById(exerciseId);
      final history = await database.getAll(
        'SELECT id FROM exercise_history WHERE exercise_id = ?',
        [exerciseId],
      );

      expect(reloaded!.srsState.learningStepIndex, -1);
      expect(reloaded.srsState.lastReview, answeredAt);
      expect(history, hasLength(1));
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

    test('foreign keys reject orphan active-session exercises', () async {
      final pragma = await database.get('PRAGMA foreign_keys;');
      expect(pragma['foreign_keys'], 1);

      await database.execute('''
        INSERT INTO session_result (
          id,
          session_type_index,
          number_unique_exercises_completed
        ) VALUES (1, 0, 0)
      ''');

      await expectLater(
        database.execute('''
          INSERT INTO active_session_exercise (
            session_result_id,
            exercise_id,
            status_index
          ) VALUES (1, 999, 0)
        '''),
        throwsA(anything),
      );
    });
  });
}
