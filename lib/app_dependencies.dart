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
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Creates and owns the long-lived dependencies shared by the application.
class AppDependencies {
  final SqliteDatabase _database;

  late final ContentController contentController;
  late final SessionController sessionController;
  late final StatisticController statisticController;
  late final ContentRenderer contentRenderer;

  AppDependencies._(this._database, sqlite.SqliteDatabase connection) {
    final contentRepository = ContentRepository(connection);
    final sessionRepository = SessionRepository(connection);

    contentController = ContentController(
      contentRepository: contentRepository,
      mediaRepository: MediaRepository(connection),
    );
    sessionController = SessionController(
      sessionRepository: sessionRepository,
      exerciseRepository: ExerciseRepository(connection),
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
    final connection = await database.open();
    return AppDependencies._(database, connection);
  }

  Future<void> dispose() => _database.close();
}
