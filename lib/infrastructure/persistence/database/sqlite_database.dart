import 'package:path_provider/path_provider.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

class SqliteDatabase {
  final MigrationRunner migrationRunner = createMigrationRunner();

  sqlite.SqliteDatabase? _database;

  SqliteDatabase();

  Future<sqlite.SqliteDatabase> open() async {
    if (_database != null) {
      return _database!;
    }

    final directory = await getApplicationSupportDirectory();
    final path = '${directory.path}/psitta.db';

    final database = sqlite.SqliteDatabase(path: path);

    await migrationRunner.migrate(database);

    _database = database;

    return database;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  sqlite.SqliteDatabase get database {
    final database = _database;

    if (database == null) {
      throw StateError('Database is not opened. Call open() before accessing it.');
    }

    return database;
  }
}
