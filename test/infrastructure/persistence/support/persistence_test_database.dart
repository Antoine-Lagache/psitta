import 'dart:io';

import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/psitta_sqlite_open_factory.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Owns an isolated, file-backed SQLite database for one persistence test.
final class PersistenceTestDatabase {
  final Directory directory;
  final sqlite.SqliteDatabase database;

  PersistenceTestDatabase._({required this.directory, required this.database});

  static Future<PersistenceTestDatabase> create({bool migrate = true}) async {
    final directory = await Directory.systemTemp.createTemp('psitta_test_');
    final database = sqlite.SqliteDatabase.withFactory(
      PsittaSqliteOpenFactory(path: '${directory.path}/test.db'),
    );

    try {
      await database.initialize();
      if (migrate) {
        await createMigrationRunner().migrate(database);
      }
      return PersistenceTestDatabase._(directory: directory, database: database);
    } on Object {
      await database.close();
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<int> insertContent() {
    return database.writeTransaction((transaction) async {
      final result = await transaction.execute(
        'INSERT INTO content DEFAULT VALUES RETURNING id',
      );
      return result.first['id'] as int;
    });
  }

  Future<int> countRows(String table) {
    return database.readTransaction((transaction) async {
      final rows = await transaction.getAll('SELECT COUNT(*) AS count FROM $table');
      return rows.single['count'] as int;
    });
  }

  Future<void> dispose() async {
    await database.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
