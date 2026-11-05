import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

/// Stores which immutable bundled content releases have been applied.
final class V3ContentReleaseSchema implements DatabaseMigration {
  @override
  int get version => 3;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('''
      CREATE TABLE installed_content_release (
        release_id TEXT PRIMARY KEY,
        manifest_sha256 TEXT NOT NULL,
        installed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      ''');
  }
}