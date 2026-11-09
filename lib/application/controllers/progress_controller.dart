import 'dart:typed_data';

import 'package:psitta/infrastructure/persistence/repositories/progress_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/database_backup_repository.dart';

class ContentImportAfterRestoreException implements Exception {
  final Object cause;

  const ContentImportAfterRestoreException(this.cause);

  @override
  String toString() => cause.toString();
}

/// Coordinates destructive operations on learner progression.
class ProgressController {
  final ProgressRepository _repository;
  final DatabaseBackupRepository _backups;
  final Future<void> Function()? _afterRestore;

  ProgressController(this._repository, this._backups, {Future<void> Function()? afterRestore})
    : _afterRestore = afterRestore;

  int get currentSchemaVersion => _backups.schemaVersion;

  Future<void> resetAllProgress() => _repository.resetAllProgress();

  Future<Uint8List> createDatabaseBackup() => _backups.createDatabaseBackup();

  Future<int> inspectDatabaseBackup(Uint8List bytes) =>
      _backups.inspectDatabaseBackup(bytes);

  Future<void> restoreDatabaseBackup(Uint8List bytes, {required bool allowMigration}) async {
    await _backups.restoreDatabaseBackup(bytes, allowMigration: allowMigration);
    try {
      await _afterRestore?.call();
    } on Object catch (error) {
      throw ContentImportAfterRestoreException(error);
    }
  }
}
