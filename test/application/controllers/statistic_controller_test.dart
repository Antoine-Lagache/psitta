import 'package:psitta/application/controllers/statistic_controller.dart';
import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import '../../infrastructure/persistence/support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late ExerciseRepository exerciseRepository;
  late SessionRepository sessionRepository;
  late StatisticController controller;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    exerciseRepository = ExerciseRepository(database);
    sessionRepository = SessionRepository(
      database,
      exerciseRepository: exerciseRepository,
    );
    controller = StatisticController(
      sessionRepository: sessionRepository,
      exerciseHistoryRepository: ExerciseHistoryRepository(database),
    );
  });

  tearDown(() => testDatabase.dispose());

  Future<WordExercise> createWordExercise() async {
    final exerciseId = await exerciseRepository.createWordExercise(
      await testDatabase.insertContent(),
    );
    return await exerciseRepository.getById(exerciseId) as WordExercise;
  }

  Session createSession(WordExercise exercise) {
    return Session(
      exercises: [exercise],
      sessionType: SessionType.wordSession,
      config: SRSConfig(),
    );
  }

  group('StatisticController', () {
    test('session statistics exclude unfinished sessions', () async {
      final exercise = await createWordExercise();
      final startedAt = DateTime.utc(2026, 9, 14, 10);

      final unfinished = createSession(exercise);
      unfinished.beginSession(startedAt);
      unfinished.intermediateResult.id = await sessionRepository.save(unfinished);

      final completed = createSession(exercise);
      completed.beginSession(startedAt.add(const Duration(hours: 1)));
      completed.intermediateResult.id = await sessionRepository.save(completed);
      completed.addTimeSpent(const Duration(minutes: 3));
      completed.endSession(
        startedAt.add(const Duration(hours: 1, minutes: 3)),
      );
      await sessionRepository.completeSession(completed);

      final statistics = await controller.getSessionStatistics();

      expect(statistics.numberOfSessions, 1);
      expect(statistics.numberOfAnswers, 0);
      expect(statistics.averageNumberOfAnswersPerSession, 0);
      expect(statistics.totalTimeSpent, const Duration(minutes: 3));
    });

    test('session answer counters keep their answer semantics', () async {
      final exercise = await createWordExercise();
      final startedAt = DateTime.utc(2026, 9, 14, 10);
      final answeredAt = startedAt.add(const Duration(minutes: 1));
      final session = createSession(exercise);
      session.beginSession(startedAt);
      session.intermediateResult.id = await sessionRepository.save(session);
      final answeredExercise = session.currentExercise;

      session.submitAnswer(
        SubmittedExerciseAnswer(
          grade: Grade.easy,
          answeredAt: answeredAt,
        ),
      );
      session.addTimeSpent(const Duration(minutes: 1));
      session.endSession(answeredAt);
      await sessionRepository.saveAnswerProgress(session, answeredExercise);

      final statistics = await controller.getSessionStatistics();

      expect(statistics.numberOfAnswers, 1);
      expect(
        statistics.getNumberOfAnswersByStatus(ExerciseStatus.newExercise),
        1,
      );
      expect(statistics.numberOfExercisesCompleted, 1);
      expect(statistics.averageNumberOfAnswersPerSession, 1);
    });
  });
}
