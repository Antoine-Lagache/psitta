import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'database_migration.dart';

/// Re-encodes historical SM-2 grades using the four FSRS rating values.
class V3GradeValues implements DatabaseMigration {
  @override
  int get version => 3;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    final invalidRows = await database.getAll('''
      SELECT id, grade
      FROM exercise_history
      WHERE grade NOT IN (0, 2, 3, 4, 5)
      LIMIT 1
      ''');
    if (invalidRows.isNotEmpty) {
      throw StateError(
        'Cannot migrate unknown legacy grade ${invalidRows.first['grade']} '
        'on history row ${invalidRows.first['id']}',
      );
    }

    await database.execute('''
      UPDATE exercise_history
      SET grade = CASE grade
        WHEN 0 THEN 1
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        WHEN 5 THEN 4
      END
      ''');
  }
}
