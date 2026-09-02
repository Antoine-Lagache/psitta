import 'migration_runner.dart';
import 'migrations/v1_initial_schema.dart';
import 'migrations/v2_srs_and_session_integrity.dart';

/// Contain the list of all migration
/// it will be usefull when more migration will be added
MigrationRunner createMigrationRunner() {
  return MigrationRunner(migrations: [V1InitialSchema(), V2SrsAndSessionIntegrity()]);
}
