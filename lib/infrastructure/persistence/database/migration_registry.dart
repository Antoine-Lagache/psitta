import 'migration_runner.dart';
import 'migrations/v1_initial_schema.dart';

MigrationRunner createMigrationRunner() {
  return MigrationRunner(migrations: [V1InitialSchema()]);
}
