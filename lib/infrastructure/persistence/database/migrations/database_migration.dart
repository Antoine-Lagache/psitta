import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// All futur migrations must implement this interface
abstract interface class DatabaseMigration {
  int get version;

  Future<void> migrate(sqlite.SqliteWriteContext database);
}
