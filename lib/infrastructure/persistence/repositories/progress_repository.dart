import 'dart:io';
import 'dart:typed_data';

import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/psitta_sqlite_open_factory.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Resets learner progress while preserving content and app preferences.
class ProgressRepository {
  final sqlite.SqliteDatabase database;
  final MigrationRunner migrationRunner;

  ProgressRepository(this.database, {required this.migrationRunner});

  int get schemaVersion => migrationRunner.latestVersion;

  Future<void> resetAllProgress() async {
    await database.writeTransaction((txn) async {
      await txn.execute(
        '''
        UPDATE srs_state
        SET state = ?, step = NULL, stability = NULL, difficulty = NULL,
            due = 0, last_review = NULL
        ''',
        [fsrs.State.learning.value],
      );
      await txn.execute('''
        UPDATE sentence_state
        SET shown_count = 0, accumulated_score = 0, is_in_learning = 0
        ''');
      await txn.execute('DELETE FROM exercise_history');
      await txn.execute('DELETE FROM session_result');
      await txn.execute(
        "DELETE FROM app_setting WHERE key LIKE 'statistics.daily_streak.%'",
      );
    });
  }

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

  /// Validates a backup and tests any required migrations on a temporary copy.
  /// Returns its original schema version for the confirmation shown in Settings.
  Future<int> inspectDatabaseBackup(Uint8List bytes) {
    return _withTemporaryBackup(bytes, (path) async {
      sqlite.SqliteDatabase? backup;
      try {
        backup = await _openBackupDatabase(path);
        final originalVersion = await _readAndValidateVersion(backup);
        await _prepareBackupDatabase(backup, originalVersion);
        await _validateCompatibleSchema(backup);
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

  /// Replaces all rows atomically, migrating an older backup only when allowed.
  Future<void> restoreDatabaseBackup(Uint8List bytes, {required bool allowMigration}) {
    return _withTemporaryBackup(bytes, (path) async {
      sqlite.SqliteDatabase? backup;
      try {
        backup = await _openBackupDatabase(path);
        final originalVersion = await _readAndValidateVersion(backup);
        if (originalVersion < schemaVersion && !allowMigration) {
          throw StateError('Migration of this older backup was not confirmed.');
        }
        await _prepareBackupDatabase(backup, originalVersion);
        await _validateCompatibleSchema(backup);
      } on UnsupportedError {
        rethrow;
      } on FormatException {
        rethrow;
      } on Object catch (error) {
        throw FormatException('This is not a valid Psitta database backup: $error');
      } finally {
        if (backup != null) await backup.close();
      }

      // ATTACH/DETACH are connection-scoped SQLite operations and must run
      // outside a transaction. Detach a stale alias first in case a previous
      // restore failed while cleaning up.
      await database.writeLock((tx) async {
        await _detachRestoreSourceIfAttached(tx);
        final result = await tx.get('PRAGMA foreign_keys');
        final wasEnabled = result['foreign_keys'] == 1;
        await tx.execute('PRAGMA foreign_keys = OFF');
        try {
          await tx.execute('ATTACH DATABASE ? AS restore_source', [path]);
          await tx.execute('BEGIN IMMEDIATE');
          try {
            final version = await tx.get('PRAGMA restore_source.user_version');
            final backupVersion = version['user_version'] as int;
            if (backupVersion != schemaVersion) {
              throw StateError('The backup could not be migrated to the current version.');
            }

            final sourceTables = await tx.getAll('''
              SELECT name FROM restore_source.sqlite_master
              WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
              ORDER BY name
              ''');
            final destinationTables = await tx.getAll('''
              SELECT name FROM main.sqlite_master
              WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
              ORDER BY name
              ''');
            final destinationNames = destinationTables
                .map((row) => row['name'] as String)
                .toList();
            final sourceNames = sourceTables.map((row) => row['name'] as String).toList();

            for (final table in destinationNames) {
              await tx.execute('DELETE FROM main.${_quoteIdentifier(table)}');
            }
            for (final table in sourceNames) {
              final name = _quoteIdentifier(table);
              await tx.execute('INSERT INTO main.$name SELECT * FROM restore_source.$name');
            }
            await tx.execute('PRAGMA main.user_version = $schemaVersion');
            final foreignKeyErrors = await tx.getAll('PRAGMA main.foreign_key_check');
            if (foreignKeyErrors.isNotEmpty) {
              throw const FormatException('The backup contains invalid database references.');
            }
            await tx.execute('COMMIT');
          } on Object {
            await tx.execute('ROLLBACK');
            rethrow;
          }
        } on Object {
          if (wasEnabled) await tx.execute('PRAGMA foreign_keys = ON');
          rethrow;
        } finally {
          await _detachRestoreSourceIfAttached(tx);
          await tx.execute('PRAGMA foreign_keys = ${wasEnabled ? 'ON' : 'OFF'}');
        }
      });
      await database.refreshSchema();
    });
  }

  Future<void> _detachRestoreSourceIfAttached(sqlite.SqliteWriteContext tx) async {
    final databases = await tx.getAll('PRAGMA database_list');
    if (databases.any((database) => database['name'] == 'restore_source')) {
      await tx.execute('DETACH DATABASE restore_source');
    }
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
    final tables = await source.getAll('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
      ''');
    final result = <String, List<String>>{};
    for (final row in tables) {
      final table = row['name'] as String;
      final columns = await source.getAll(
        'PRAGMA table_info(${_quoteIdentifier(table)})',
      );
      final schema = columns
          .map(
            (column) => [
              column['name'],
              column['type'],
              column['notnull'],
              column['dflt_value'],
              column['pk'],
            ].join('\u001f'),
          )
          .toList();
      final foreignKeys = await source.getAll(
        'PRAGMA foreign_key_list(${_quoteIdentifier(table)})',
      );
      schema.addAll(
        foreignKeys.map(
          (key) => 'FK:${[
            key['id'],
            key['seq'],
            key['table'],
            key['from'],
            key['to'],
            key['on_update'],
            key['on_delete'],
            key['match'],
          ].join('\u001f')}',
        ),
      );
      final indexes = await source.getAll(
        "SELECT sql FROM sqlite_master WHERE type = 'index' "
        'AND tbl_name = ? AND sql IS NOT NULL ORDER BY name',
        [table],
      );
      schema.addAll(indexes.map((index) => 'INDEX:${index['sql']}'));
      result[table] = schema;
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
