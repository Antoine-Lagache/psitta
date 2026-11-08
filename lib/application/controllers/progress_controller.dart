import 'dart:typed_data';

import 'package:psitta/infrastructure/persistence/repositories/progress_repository.dart';

/// Coordinates destructive operations on learner progression.
class ProgressController {
  final ProgressRepository _repository;

  ProgressController(this._repository);

  int get currentSchemaVersion => _repository.schemaVersion;

  Future<void> resetAllProgress() => _repository.resetAllProgress();

  Future<Uint8List> createDatabaseBackup() => _repository.createDatabaseBackup();

  Future<int> inspectDatabaseBackup(Uint8List bytes) =>
      _repository.inspectDatabaseBackup(bytes);

  Future<void> restoreDatabaseBackup(Uint8List bytes, {required bool allowMigration}) =>
      _repository.restoreDatabaseBackup(bytes, allowMigration: allowMigration);
}
