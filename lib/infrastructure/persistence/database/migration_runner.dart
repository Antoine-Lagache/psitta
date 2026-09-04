import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/database/migrations/database_migration.dart';

/// Applies pending migrations and advances SQLite's `user_version` atomically.
class MigrationRunner {
  final List<DatabaseMigration> migrations;

  MigrationRunner({required this.migrations});

  /// Applies each migration newer than the database's current version.
  Future<void> migrate(sqlite.SqliteDatabase database) async {
    final currentVersion = await _getCurrentVersion(database);

    final sortedMigrations = [...migrations]..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in sortedMigrations) {
      if (migration.version <= currentVersion) {
        continue;
      }

      // Keep the schema change and its version update in the same transaction.
      await database.writeTransaction((tx) async {
        await migration.migrate(tx);
        await _setVersion(tx, migration.version);
      });
    }
  }

  Future<int> _getCurrentVersion(sqlite.SqliteDatabase database) async {
    final result = await database.get('PRAGMA user_version;');

    return result['user_version'] as int;
  }

  Future<void> _setVersion(sqlite.SqliteWriteContext database, int version) async {
    await database.execute('PRAGMA user_version = $version;');
  }
}
