import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/sentence_group_repository.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late ExerciseRepository repository;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    repository = ExerciseRepository(database);
  });

  tearDown(() => testDatabase.dispose());

  group('ExerciseRepository', () {
    test('enables foreign-key enforcement', () async {
      final foreignKeysEnabled = await database.writeTransaction((transaction) async {
        final result = await transaction.getAll('PRAGMA foreign_keys');
        return result.single['foreign_keys'];
      });

      expect(foreignKeysEnabled, 1);
    });

    test('createWordExercise creates and returns an exercise id', () async {
      final contentId = await testDatabase.insertContent();

      final exerciseId = await repository.createWordExercise(contentId);

      expect(exerciseId, greaterThan(0));

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isA<WordExercise>());
      final wordExercise = exercise as WordExercise;
      expect(wordExercise.id, exerciseId);
      expect(wordExercise.contentId, contentId);
      expect(wordExercise.status, ExerciseStatus.newExercise);
      expect(wordExercise.srsState.learningStepIndex, 0);
      expect(wordExercise.srsState.lastReview, isNull);
    });

    test('createSentenceExercise rejects an empty sentence group', () async {
      await database.execute('INSERT INTO sentence_group (id) VALUES (1)');

      await expectLater(
        repository.createSentenceExercise(1, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createSentenceExercise creates and returns an exercise id', () async {
      final contentId = await testDatabase.insertContent();
      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      final sentenceInstanceId = await sentenceGroupRepository.createInstance(
        sentenceGroupId,
        contentId,
      );

      final exerciseId = await repository.createSentenceExercise(sentenceGroupId, 1);

      expect(exerciseId, greaterThan(0));

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isA<SentenceExercise>());
      final sentenceExercise = exercise as SentenceExercise;
      expect(sentenceExercise.id, exerciseId);
      expect(sentenceExercise.groupId, sentenceGroupId);
      expect(sentenceExercise.trainingCountMax, 1);
      expect(sentenceExercise.trainingCount, 1);
      expect(sentenceExercise.sentences.sentences, hasLength(1));
      expect(sentenceExercise.sentences.sentences.single.id, sentenceInstanceId);
      expect(sentenceExercise.sentences.sentences.single.contentId, contentId);
    });

    test('prevents deleting a sentence group used by an exercise', () async {
      final contentId = await testDatabase.insertContent();
      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      await sentenceGroupRepository.createInstance(sentenceGroupId, contentId);
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
      final contentId = await testDatabase.insertContent();

      final exerciseId = await repository.createWordExercise(contentId);

      final exercises = await repository.getNewExercises(10, 'word');

      expect(exercises, hasLength(1));
      expect(exercises.first.id, exerciseId);
      expect(exercises.first, isA<WordExercise>());
    });

    test('getDueExercises returns due exercises', () async {
      final contentId = await testDatabase.insertContent();

      final exerciseId = await repository.createWordExercise(contentId);

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

    test('countNewExercises counts exercises with no history by type', () async {
      final firstContentId = await testDatabase.insertContent();
      final secondContentId = await testDatabase.insertContent();
      final wordExerciseId = await repository.createWordExercise(firstContentId);

      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      await sentenceGroupRepository.createInstance(sentenceGroupId, secondContentId);
      await repository.createSentenceExercise(sentenceGroupId, 1);

      final reviewedWord = await repository.getById(wordExerciseId) as WordExercise;
      reviewedWord.newHistoryEntry.add(
        ExerciseHistoryEntry(
          exerciseId: wordExerciseId,
          grade: Grade.good,
          answeredAt: DateTime.utc(2026, 9, 18),
          status: ExerciseStatus.newExercise,
        ),
      );
      await repository.save(reviewedWord);

      expect(await repository.countNewExercises('word'), 0);
      expect(await repository.countNewExercises('sentence'), 1);
      expect(await repository.countNewExercises(null), 1);
    });

    test('countDueExercises filters by type and includes the exact boundary', () async {
      final now = DateTime.utc(2026, 9, 18, 12);
      final firstContentId = await testDatabase.insertContent();
      final secondContentId = await testDatabase.insertContent();
      final thirdContentId = await testDatabase.insertContent();
      final dueWordId = await repository.createWordExercise(firstContentId);
      final futureWordId = await repository.createWordExercise(secondContentId);

      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      await sentenceGroupRepository.createInstance(sentenceGroupId, thirdContentId);
      final dueSentenceId = await repository.createSentenceExercise(sentenceGroupId, 1);

      await database.execute(
        '''
        UPDATE srs_state
        SET next_review = CASE exercise_id
          WHEN ? THEN ?
          WHEN ? THEN ?
          WHEN ? THEN ?
        END
        WHERE exercise_id IN (?, ?, ?)
        ''',
        [
          dueWordId,
          now.microsecondsSinceEpoch,
          futureWordId,
          now.add(const Duration(microseconds: 1)).microsecondsSinceEpoch,
          dueSentenceId,
          now.subtract(const Duration(days: 1)).microsecondsSinceEpoch,
          dueWordId,
          futureWordId,
          dueSentenceId,
        ],
      );

      expect(await repository.countDueExercises(now, 'word'), 1);
      expect(await repository.countDueExercises(now, 'sentence'), 1);
      expect(await repository.countDueExercises(now, null), 2);
    });

    test('save round-trips every word SRS field', () async {
      final contentId = await testDatabase.insertContent();

      final exerciseId = await repository.createWordExercise(contentId);
      final exercise = await repository.getById(exerciseId);
      final reviewedAt = DateTime.utc(2026, 9, 4, 12, 30, 15, 250);

      final wordExercise = exercise as WordExercise;
      wordExercise.srsState = SRSState(
        easeFactor: 2.1,
        interval: const Duration(days: 7, minutes: 3),
        kFactor: 0.25,
        w: 0.2,
        rbar: 0.4,
        lastReview: reviewedAt,
        learningStepIndex: -1,
      );
      await repository.save(wordExercise);

      final savedExercise = await repository.getById(exerciseId);

      expect(savedExercise, isNotNull);
      expect(savedExercise!.id, exerciseId);
      expect(savedExercise.srsState.easeFactor, 2.1);
      expect(savedExercise.srsState.interval, const Duration(days: 7, minutes: 3));
      expect(savedExercise.srsState.kFactor, 0.25);
      expect(savedExercise.srsState.w, 0.2);
      expect(savedExercise.srsState.rbar, 0.4);
      expect(savedExercise.srsState.lastReview?.toUtc(), reviewedAt);
      expect(savedExercise.srsState.learningStepIndex, -1);
    });

    test('answer persistence rolls back when the session update fails', () async {
      final contentId = await testDatabase.insertContent();
      final exerciseId = await repository.createWordExercise(contentId);
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
      final persistedSessionId = await sessionRepository.save(session);
      session.intermediateResult.id = persistedSessionId;
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
      expect(
        await ExerciseHistoryRepository(database).getList(exerciseId: exerciseId),
        isEmpty,
      );

      final activeSnapshots = await database.readTransaction(
        (transaction) => transaction.getAll(
          'SELECT status_index FROM active_session_exercise WHERE session_result_id = ?',
          [persistedSessionId],
        ),
      );
      expect(activeSnapshots, hasLength(1));
      expect(activeSnapshots.single['status_index'], ExerciseStatus.newExercise.code);
    });

    test('delete removes an exercise', () async {
      final contentId = await testDatabase.insertContent();

      final exerciseId = await repository.createWordExercise(contentId);

      await repository.delete(exerciseId);

      final exercise = await repository.getById(exerciseId);

      expect(exercise, isNull);
      expect(await testDatabase.countRows('srs_state'), 0);
      expect(await testDatabase.countRows('word_exercise'), 0);
    });

    test('resetProgress removes history and restores initial word state', () async {
      final contentId = await testDatabase.insertContent();

      final exerciseId = await repository.createWordExercise(contentId);

      final exercise = await repository.getById(exerciseId);
      final wordExercise = exercise as WordExercise;

      wordExercise.newHistoryEntry.add(
        ExerciseHistoryEntry(
          exerciseId: exerciseId,
          grade: Grade.good,
          answeredAt: DateTime.utc(2026, 9, 4, 12),
          status: ExerciseStatus.newExercise,
        ),
      );
      wordExercise.srsState = SRSState(
        easeFactor: 1.8,
        interval: const Duration(days: 12),
        kFactor: 0.2,
        w: 0.3,
        rbar: 0.5,
        lastReview: DateTime.utc(2026, 9, 4, 12),
        learningStepIndex: -1,
      );
      await repository.save(wordExercise);

      await repository.resetProgress(exerciseId);

      final resetExercise = await repository.getById(exerciseId);

      expect(resetExercise, isNotNull);
      expect(resetExercise!.id, exerciseId);
      expect(resetExercise.status, ExerciseStatus.newExercise);
      expect(resetExercise.srsState.easeFactor, 2.5);
      expect(resetExercise.srsState.interval, const Duration(days: 1));
      expect(resetExercise.srsState.kFactor, 0.1);
      expect(resetExercise.srsState.w, 0.0);
      expect(resetExercise.srsState.rbar, 0.0);
      expect(resetExercise.srsState.lastReview, isNull);
      expect(resetExercise.srsState.learningStepIndex, 0);
      expect(
        await ExerciseHistoryRepository(database).getList(exerciseId: exerciseId),
        isEmpty,
      );
    });

    test('save and reset round-trip sentence progress', () async {
      final contentId = await testDatabase.insertContent();
      final sentenceGroupRepository = SentenceGroupRepository(database);
      final sentenceGroupId = await sentenceGroupRepository.createGroup();
      final sentenceInstanceId = await sentenceGroupRepository.createInstance(
        sentenceGroupId,
        contentId,
      );
      final exerciseId = await repository.createSentenceExercise(sentenceGroupId, 1);
      final exercise = await repository.getById(exerciseId) as SentenceExercise;
      final sentence = exercise.sentences.sentences.single;
      final reviewedAt = DateTime.utc(2026, 9, 4, 14);

      sentence.state.shownCount = 4;
      sentence.state.accumulatedScore = 2.7;
      sentence.state.isInLearning = true;
      exercise.srsState = SRSState(
        interval: const Duration(days: 3),
        lastReview: reviewedAt,
        learningStepIndex: -1,
      );
      exercise.newHistoryEntry.add(
        ExerciseHistoryEntry(
          exerciseId: exerciseId,
          grade: Grade.medium,
          answeredAt: reviewedAt,
          status: ExerciseStatus.newExercise,
          sentenceInstanceId: sentenceInstanceId,
        ),
      );

      await repository.save(exercise);

      final persisted = await repository.getById(exerciseId) as SentenceExercise;
      final persistedSentence = persisted.sentences.sentences.single;
      expect(exercise.newHistoryEntry, isEmpty);
      expect(persisted.status, ExerciseStatus.toReview);
      expect(persisted.srsState.lastReview?.toUtc(), reviewedAt);
      expect(persistedSentence.state.shownCount, 4);
      expect(persistedSentence.state.accumulatedScore, 2.7);
      expect(persistedSentence.state.isInLearning, isTrue);

      await repository.resetProgress(exerciseId);

      final reset = await repository.getById(exerciseId) as SentenceExercise;
      final resetSentence = reset.sentences.sentences.single;
      expect(reset.status, ExerciseStatus.newExercise);
      expect(reset.srsState.lastReview, isNull);
      expect(reset.srsState.learningStepIndex, 0);
      expect(resetSentence.state.shownCount, 0);
      expect(resetSentence.state.accumulatedScore, 0.0);
      expect(resetSentence.state.isInLearning, isFalse);
      expect(
        await ExerciseHistoryRepository(database).getList(exerciseId: exerciseId),
        isEmpty,
      );
    });
  });
}
