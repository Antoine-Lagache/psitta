import 'dart:io';

import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  late Directory temporaryDirectory;
  late sqlite.SqliteDatabase database;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('psitta_test_');
    database = sqlite.SqliteDatabase(path: '${temporaryDirectory.path}/test.db');
    await createMigrationRunner().migrate(database);
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('an active session can be saved and resumed with a current exercise', () async {
    final exerciseRepository = ExerciseRepository(database);
    final sessionRepository = SessionRepository(database);
    await database.execute('INSERT INTO content (id) VALUES (1)');
    final exerciseId = await exerciseRepository.createWordExercise(1);
    final exercise = await exerciseRepository.getById(exerciseId);

    final session = Session(
      exercises: [exercise!],
      sessionType: SessionType.wordSession,
      config: SRSConfig(),
    )..beginSession(DateTime.utc(2026, 9, 2, 12));

    session.intermediateResult.id = await sessionRepository.save(session);

    final activeResults = await sessionRepository.getAllActiveSessionResult();
    final resumed = await sessionRepository.getActiveSession(
      activeResults.single,
      SRSConfig(),
    );

    expect(resumed.currentExercise.id, exerciseId);
    expect(resumed.currentExercise.status, ExerciseStatus.newExercise);
  });
}
