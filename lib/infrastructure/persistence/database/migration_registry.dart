import 'migration_runner.dart';
import 'migrations/v1_initial_schema.dart';

/// Builds the ordered registry of schema migrations known by the application.
MigrationRunner createMigrationRunner() {
  return MigrationRunner(migrations: [V1InitialSchema()]);
}
