import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_history_dao.dart';
import 'package:psitta/infrastructure/persistence/models/exercise_history/exercise_history_persistence.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late ExerciseHistoryDao historyDao;
  late ExerciseHistoryRepository repository;
  late ExerciseRepository exerciseRepository;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    historyDao = ExerciseHistoryDao(database);
    repository = ExerciseHistoryRepository(database);
    exerciseRepository = ExerciseRepository(database);
  });

  tearDown(() => testDatabase.dispose());

  Future<int> createWordExercise() async {
    return exerciseRepository.createWordExercise(await testDatabase.insertContent());
  }

  Future<void> insertHistory({
    required int exerciseId,
    required Grade grade,
    required DateTime answeredAt,
    required ExerciseStatus status,
  }) async {
    await historyDao.insert(
      ExerciseHistoryPersistence(
        exerciseId: exerciseId,
        grade: grade.toInt(),
        answeredAt: toIsoUtc(answeredAt)!,
        status: status.code,
      ),
    );
  }

  group('ExerciseHistoryRepository', () {
    test('maps entries and applies an exercise-scoped half-open range', () async {
      final firstExerciseId = await createWordExercise();
      final secondExerciseId = await createWordExercise();
      final start = DateTime.utc(2026, 9, 5, 9);
      final middle = start.add(const Duration(hours: 1));
      final end = start.add(const Duration(hours: 2));

      await insertHistory(
        exerciseId: firstExerciseId,
        grade: Grade.again,
        answeredAt: start,
        status: ExerciseStatus.newExercise,
      );
      await insertHistory(
        exerciseId: firstExerciseId,
        grade: Grade.good,
        answeredAt: middle,
        status: ExerciseStatus.learning,
      );
      await insertHistory(
        exerciseId: firstExerciseId,
        grade: Grade.easy,
        answeredAt: end,
        status: ExerciseStatus.toReview,
      );
      await insertHistory(
        exerciseId: secondExerciseId,
        grade: Grade.medium,
        answeredAt: middle.add(const Duration(minutes: 1)),
        status: ExerciseStatus.toReview,
      );

      final entries = await repository.getList(
        exerciseId: firstExerciseId,
        startDate: start,
        endDate: end,
      );

      expect(entries, hasLength(2));
      expect(entries.first.id, isNotNull);
      expect(entries.first.exerciseId, firstExerciseId);
      expect(entries.first.grade, Grade.good);
      expect(entries.first.status, ExerciseStatus.learning);
      expect(entries.first.answeredAt.toUtc(), middle);
      expect(entries.first.sentenceInstanceId, isNull);
      expect(entries.last.grade, Grade.again);
      expect(entries.last.answeredAt.toUtc(), start);
    });

    test('returns all exercises in reverse chronological order', () async {
      final firstExerciseId = await createWordExercise();
      final secondExerciseId = await createWordExercise();
      final earlier = DateTime.utc(2026, 9, 5, 9);
      final later = earlier.add(const Duration(minutes: 1));

      await insertHistory(
        exerciseId: firstExerciseId,
        grade: Grade.good,
        answeredAt: earlier,
        status: ExerciseStatus.newExercise,
      );
      await insertHistory(
        exerciseId: secondExerciseId,
        grade: Grade.medium,
        answeredAt: later,
        status: ExerciseStatus.toReview,
      );

      final entries = await repository.getList();

      expect(
        entries.map((entry) => entry.exerciseId),
        orderedEquals([secondExerciseId, firstExerciseId]),
      );
    });
  });
}
