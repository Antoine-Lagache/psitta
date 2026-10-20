import 'package:path_provider/path_provider.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/psitta_sqlite_open_factory.dart';
import 'package:psitta/infrastructure/persistence/release/bundled_database_installer.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Owns the application database lifecycle and runs migrations before use.
class SqliteDatabase {
  final MigrationRunner migrationRunner;
  final String? _path;
  final BundledDatabaseInstaller _installer;
  Future<sqlite.SqliteDatabase>? _opening;

  sqlite.SqliteDatabase? _database;

  SqliteDatabase({
    String? path,
    BundledDatabaseInstaller? installer,
    MigrationRunner? migrationRunner,
  }) : _path = path,
       _installer = installer ?? BundledDatabaseInstaller(),
       migrationRunner = migrationRunner ?? createMigrationRunner();

  /// Opens and migrates the database, reusing the existing connection if open.
  Future<sqlite.SqliteDatabase> open() {
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<sqlite.SqliteDatabase> _open() async {
    if (_database != null) {
      return _database!;
    }

    final path = _path ?? '${(await getApplicationSupportDirectory()).path}/psitta.db';
    await _installer.installIfMissing(path, latestVersion: migrationRunner.latestVersion);

    final database = sqlite.SqliteDatabase.withFactory(
      PsittaSqliteOpenFactory(path: path),
    );

    try {
      await database.initialize();
      await migrationRunner.migrate(database);
    } on Object {
      await database.close();
      rethrow;
    }

    _database = database;

    return database;
  }

  Future<void> close() async {
    await _opening;
    await _database?.close();
    _database = null;
  }

  /// Returns the open connection or fails when [open] has not completed.
  sqlite.SqliteDatabase get database {
    final database = _database;

    if (database == null) {
      throw StateError('Database is not opened. Call open() before accessing it.');
    }

    return database;
  }
}
