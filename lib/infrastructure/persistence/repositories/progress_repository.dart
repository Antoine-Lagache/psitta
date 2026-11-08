import 'dart:io';
import 'dart:typed_data';

import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Resets learner progress while preserving content and app preferences.
class ProgressRepository {
  final sqlite.SqliteDatabase database;
  final int schemaVersion;

  ProgressRepository(this.database, {required this.schemaVersion});

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

  /// Replaces all rows atomically after verifying the backup schema version.
  Future<void> restoreDatabaseBackup(Uint8List bytes) async {
    final backup = File(
      '${Directory.systemTemp.path}/psitta-restore-${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await backup.writeAsBytes(bytes, flush: true);
    try {
      await database.writeTransaction((tx) async {
        await tx.execute('ATTACH DATABASE ? AS restore_source', [backup.path]);
        try {
          final version = await tx.get('PRAGMA restore_source.user_version');
          final backupVersion = version['user_version'] as int;
          if (backupVersion != schemaVersion) {
            throw FormatException(
              'Backup database version $backupVersion is not supported. '
              'Expected version $schemaVersion.',
            );
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

          // Deferring constraints allows tables to be restored in any order.
          await tx.execute('PRAGMA defer_foreign_keys = ON');
          for (final table in destinationNames) {
            await tx.execute('DELETE FROM main.${_quoteIdentifier(table)}');
          }
          for (final table in sourceNames) {
            final name = _quoteIdentifier(table);
            await tx.execute('INSERT INTO main.$name SELECT * FROM restore_source.$name');
          }
          await tx.execute('PRAGMA main.user_version = $schemaVersion');
        } finally {
          await tx.execute('DETACH DATABASE restore_source');
        }
      });
      await database.refreshSchema();
    } finally {
      if (await backup.exists()) await backup.delete();
    }
  }

  String _quoteIdentifier(String identifier) => '"${identifier.replaceAll('"', '""')}"';
}
