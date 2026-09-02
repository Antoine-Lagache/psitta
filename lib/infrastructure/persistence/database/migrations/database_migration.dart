import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Defines one ordered, atomic change to the persisted database schema.
abstract interface class DatabaseMigration {
  int get version;

  Future<void> migrate(sqlite.SqliteWriteContext database);
}
