import 'dart:typed_data';

import 'package:psitta/infrastructure/persistence/repositories/progress_repository.dart';

class ContentImportAfterRestoreException implements Exception {
  final Object cause;

  const ContentImportAfterRestoreException(this.cause);

  @override
  String toString() => cause.toString();
}

/// Coordinates destructive operations on learner progression.
class ProgressController {
  final ProgressRepository _repository;
  final Future<void> Function()? _afterRestore;

  ProgressController(this._repository, {Future<void> Function()? afterRestore})
    : _afterRestore = afterRestore;

  int get currentSchemaVersion => _repository.schemaVersion;

  Future<void> resetAllProgress() => _repository.resetAllProgress();

  Future<Uint8List> createDatabaseBackup() => _repository.createDatabaseBackup();

  Future<int> inspectDatabaseBackup(Uint8List bytes) =>
      _repository.inspectDatabaseBackup(bytes);

  Future<void> restoreDatabaseBackup(Uint8List bytes, {required bool allowMigration}) async {
    await _repository.restoreDatabaseBackup(bytes, allowMigration: allowMigration);
    try {
      await _afterRestore?.call();
    } on Object catch (error) {
      throw ContentImportAfterRestoreException(error);
    }
  }
}
