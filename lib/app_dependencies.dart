import 'package:psitta/application/controllers/content_controller.dart';
import 'package:psitta/application/controllers/daily_streak_controller.dart';
import 'package:psitta/application/controllers/progress_controller.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/controllers/settings_controller.dart';
import 'package:psitta/application/controllers/statistic_controller.dart';
import 'package:psitta/application/startup/content_release_state.dart';
import 'package:psitta/infrastructure/persistence/database/sqlite_database.dart';
import 'package:psitta/infrastructure/persistence/dao/app_setting_dao.dart';
import 'package:psitta/infrastructure/persistence/release/character_exercise_release_importer.dart';
import 'package:psitta/infrastructure/persistence/release/release_content_importer.dart';
import 'package:psitta/infrastructure/persistence/release/released_content_installer.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/progress_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/database_backup_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/presentation/content/field_renderer.dart';
import 'package:psitta/ui/presentation/content/media_resolver.dart';

/// Creates and owns the long-lived dependencies shared by the application.
class AppDependencies {
  final SqliteDatabase _database;

  late final ContentController contentController;
  late final SessionController sessionController;
  late final StatisticController statisticController;
  late final SettingsController settingsController;
  late final ProgressController progressController;
  late final ContentRenderer contentRenderer;
  late final ContentReleaseState contentReleaseState;

  AppDependencies._(this._database) {
    final connection = _database.database;
    final contentRepository = ContentRepository(connection);
    final exerciseRepository = ExerciseRepository(connection);
    final sessionRepository = SessionRepository(
      connection,
      exerciseRepository: exerciseRepository,
    );
    final dailyStreakController = DailyStreakController(AppSettingDao(connection));
    settingsController = SettingsController(AppSettingDao(connection));
    progressController = ProgressController(
      ProgressRepository(connection),
      DatabaseBackupRepository(connection, migrationRunner: _database.migrationRunner),
      afterRestore: ReleasedContentInstaller(connection).installMissing,
    );

    contentController = ContentController(
      contentRepository: contentRepository,
      mediaRepository: MediaRepository(connection),
    );
    sessionController = SessionController(
      sessionRepository: sessionRepository,
      exerciseRepository: exerciseRepository,
      contentController: contentController,
      dailyStreakController: dailyStreakController,
    );
    statisticController = StatisticController(
      sessionRepository: sessionRepository,
      exerciseHistoryRepository: ExerciseHistoryRepository(connection),
      exerciseRepository: exerciseRepository,
      dailyStreakController: dailyStreakController,
    );
    contentRenderer = ContentRenderer(FieldRenderer(MediaResolver(contentController)));
  }

  static Future<AppDependencies> initialize() async {
    final database = SqliteDatabase();
    await database.open();
    try {
      await ReleaseContentImporter(database.database).importIfEmpty();
      final dependencies = AppDependencies._(database);
      dependencies.contentReleaseState = ContentReleaseState(
        CharacterExerciseReleaseImporter(database.database).importIfNeeded(),
      );
      return dependencies;
    } on Object {
      await database.close();
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await contentReleaseState.completed;
    } on Object {
      // ContentReleaseState records installation failures for the UI.
    }
    contentReleaseState.dispose();
    await _database.close();
  }
}
