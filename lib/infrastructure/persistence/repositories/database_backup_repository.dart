import 'dart:io';
import 'dart:typed_data';

import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/psitta_sqlite_open_factory.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Validates and restores SQLite snapshots without disabling foreign keys.
class DatabaseBackupRepository {
  final sqlite.SqliteDatabase database;
  final MigrationRunner migrationRunner;

  DatabaseBackupRepository(this.database, {required this.migrationRunner});

  int get schemaVersion => migrationRunner.latestVersion;

  /// Returns a consistent SQLite snapshot, including content and settings.
  Future<Uint8List> createDatabaseBackup() async {
    final snapshot = File(
      '${Directory.systemTemp.path}/psitta-backup-${DateTime.now().microsecondsSinceEpoch}.db',
    );
    try {
      await database.writeLock((tx) async {
        await tx.execute('VACUUM INTO ?', [snapshot.path]);
      });
      return await snapshot.readAsBytes();
    } finally {
      if (await snapshot.exists()) await snapshot.delete();
    }
  }

  /// Inspects the file before confirmation; migration runs only during restoration.
  /// Returns its original schema version for the confirmation shown in Settings.
  Future<int> inspectDatabaseBackup(Uint8List bytes) {
    return _withTemporaryBackup(bytes, (path) async {
      sqlite.SqliteDatabase? backup;
      try {
        backup = await _openBackupDatabase(path);
        final originalVersion = await _readAndValidateVersion(backup);
        if (originalVersion == schemaVersion) {
          await _validateCompatibleSchema(backup);
        }
        return originalVersion;
      } on UnsupportedError {
        rethrow;
      } on FormatException {
        rethrow;
      } on Object catch (error) {
        throw FormatException('This is not a valid Psitta database backup: $error');
      } finally {
        if (backup != null) await backup.close();
      }
    });
  }

  /// Prepares the source completely before replacing the destination atomically.
  Future<void> restoreDatabaseBackup(Uint8List bytes, {required bool allowMigration}) {
    return _withTemporaryBackup(bytes, (path) async {
      final backup = await _openBackupDatabase(path);
      try {
        final version = await _readAndValidateVersion(backup);
        if (version < schemaVersion && !allowMigration) {
          throw StateError('Migration of this older backup was not confirmed.');
        }
        await _prepareBackupDatabase(backup, version);
        await _validateCompatibleSchema(backup);
        final order = await _dependencyOrder(backup);
        // Materialize the validated snapshot before touching the active database.
        final rows = <String, List<Map<String, dynamic>>>{};
        for (final table in order) {
          rows[table] = await backup.getAll('SELECT * FROM ${_quoteIdentifier(table)}');
        }
        await database.writeTransaction((tx) async {
          // The bank history intentionally contains self-referencing foreign
          // keys. Defer checks so the full snapshot can be replaced atomically.
          await tx.execute('PRAGMA defer_foreign_keys = ON');
          for (final table in order.reversed) {
            await tx.execute('DELETE FROM ${_quoteIdentifier(table)}');
          }
          for (final table in order) {
            for (final row in rows[table]!) {
              final columns = row.keys.map(_quoteIdentifier).join(', ');
              final placeholders = List.filled(row.length, '?').join(', ');
              await tx.execute(
                'INSERT INTO ${_quoteIdentifier(table)} ($columns) VALUES ($placeholders)',
                row.values.toList(),
              );
            }
          }
          final errors = await tx.getAll('PRAGMA foreign_key_check');
          if (errors.isNotEmpty) {
            throw const FormatException('The backup contains invalid references.');
          }
        });
      } finally {
        await backup.close();
      }
    });
  }

  /// Parent tables precede children; self-references are deferred on restore.
  Future<List<String>> _dependencyOrder(sqlite.SqliteDatabase source) async {
    final tables = await source.getAll(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    final pending = <String, Set<String>>{};
    for (final table in tables) {
      final name = table['name'] as String;
      final keys = await source.getAll(
        'PRAGMA foreign_key_list(${_quoteIdentifier(name)})',
      );
      pending[name] = keys
          .map((key) => key['table'] as String)
          .where((parent) => parent != name)
          .toSet();
    }
    final ordered = <String>[];
    while (pending.isNotEmpty) {
      final ready = pending.keys.where((name) => pending[name]!.isEmpty).toList();
      if (ready.isEmpty) {
        throw const FormatException(
          'Restoring this cyclic database schema is unsupported.',
        );
      }
      ordered.addAll(ready);
      for (final name in ready) {
        pending.remove(name);
      }
      for (final parents in pending.values) {
        parents.removeAll(ready);
      }
    }
    return ordered;
  }

  Future<int> _readAndValidateVersion(sqlite.SqliteDatabase backup) async {
    final integrity = await backup.get('PRAGMA integrity_check');
    if (integrity['integrity_check'] != 'ok') {
      throw const FormatException('The selected SQLite database is corrupted.');
    }

    final result = await backup.get('PRAGMA user_version');
    final version = result['user_version'] as int;
    if (version > schemaVersion) {
      throw UnsupportedError(
        'This backup comes from a newer Psitta database version ($version). '
        'This app supports version $schemaVersion.',
      );
    }
    if (version < 1) {
      throw FormatException('Database version $version is not a valid Psitta backup.');
    }
    return version;
  }

  Future<void> _prepareBackupDatabase(
    sqlite.SqliteDatabase backup,
    int originalVersion,
  ) async {
    if (originalVersion < schemaVersion) {
      await migrationRunner.migrate(backup);
    }
    final migratedVersion = await backup.get('PRAGMA user_version');
    if (migratedVersion['user_version'] != schemaVersion) {
      throw FormatException(
        'The backup could not be migrated to database version $schemaVersion.',
      );
    }
    final foreignKeyErrors = await backup.getAll('PRAGMA foreign_key_check');
    if (foreignKeyErrors.isNotEmpty) {
      throw const FormatException('The backup contains invalid database references.');
    }
  }

  Future<void> _validateCompatibleSchema(sqlite.SqliteDatabase backup) async {
    final currentSchema = await _readTableSchema(database);
    final backupSchema = await _readTableSchema(backup);
    if (currentSchema.length != backupSchema.length ||
        currentSchema.keys.toSet().difference(backupSchema.keys.toSet()).isNotEmpty ||
        backupSchema.keys.toSet().difference(currentSchema.keys.toSet()).isNotEmpty) {
      throw const FormatException(
        'The database structure does not match a Psitta backup.',
      );
    }
    for (final table in currentSchema.keys) {
      if (!_sameList(currentSchema[table]!, backupSchema[table]!)) {
        throw FormatException('The backup has an incompatible "$table" table.');
      }
    }
  }

  Future<Map<String, List<String>>> _readTableSchema(sqlite.SqliteDatabase source) async {
    final objects = await source.getAll(
      "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL "
      "AND name NOT LIKE 'sqlite_%' ORDER BY type, name",
    );
    final result = <String, List<String>>{};
    for (final object in objects) {
      result['${object['type']}:${object['name']}'] = [object['sql'] as String];
    }
    return result;
  }

  bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  Future<sqlite.SqliteDatabase> _openBackupDatabase(String path) async {
    final backup = sqlite.SqliteDatabase.withFactory(PsittaSqliteOpenFactory(path: path));
    try {
      await backup.initialize();
      return backup;
    } on Object {
      await backup.close();
      rethrow;
    }
  }

  Future<T> _withTemporaryBackup<T>(
    Uint8List bytes,
    Future<T> Function(String path) action,
  ) async {
    final directory = await Directory.systemTemp.createTemp('psitta_backup_');
    try {
      final file = File('${directory.path}/backup.db');
      await file.writeAsBytes(bytes, flush: true);
      return await action(file.path);
    } finally {
      await directory.delete(recursive: true);
    }
  }

  String _quoteIdentifier(String identifier) => '"${identifier.replaceAll('"', '""')}"';
}
