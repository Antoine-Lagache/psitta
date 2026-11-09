import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'character_exercise_release_importer.dart';
import 'release_content_importer.dart';

/// Installs missing bundled content after a database restoration.
class ReleasedContentInstaller {
  final sqlite.SqliteDatabase database;

  ReleasedContentInstaller(this.database);

  Future<void> installMissing() async {
    await ReleaseContentImporter(database).importIfEmpty();
    await CharacterExerciseReleaseImporter(database).importIfNeeded();
  }
}
