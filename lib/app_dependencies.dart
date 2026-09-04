import 'package:psitta/application/controllers/content_controller.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/controllers/statistic_controller.dart';
import 'package:psitta/infrastructure/persistence/database/sqlite_database.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';
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
  late final ContentRenderer contentRenderer;

  AppDependencies._(this._database) {
    final connection = _database.database;
    final contentRepository = ContentRepository(connection);
    final exerciseRepository = ExerciseRepository(connection);
    final sessionRepository = SessionRepository(
      connection,
      exerciseRepository: exerciseRepository,
    );

    contentController = ContentController(
      contentRepository: contentRepository,
      mediaRepository: MediaRepository(connection),
    );
    sessionController = SessionController(
      sessionRepository: sessionRepository,
      exerciseRepository: exerciseRepository,
      contentController: contentController,
    );
    statisticController = StatisticController(
      sessionRepository: sessionRepository,
      exerciseHistoryRepository: ExerciseHistoryRepository(connection),
    );
    contentRenderer = ContentRenderer(
      FieldRenderer(MediaResolver(contentController)),
    );
  }

  static Future<AppDependencies> initialize() async {
    final database = SqliteDatabase();
    await database.open();
    return AppDependencies._(database);
  }

  Future<void> dispose() => _database.close();
}
