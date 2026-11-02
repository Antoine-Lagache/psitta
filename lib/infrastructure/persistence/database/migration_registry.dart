import 'migration_runner.dart';
import 'migrations/v1_initial_schema.dart';
import 'migrations/v2_schema.dart';
import 'migrations/v3_grade_values.dart';

/// Builds the ordered registry of schema migrations known by the application.
MigrationRunner createMigrationRunner() {
  return MigrationRunner(migrations: [V1InitialSchema(), V2Schema(), V3GradeValues()]);
}
