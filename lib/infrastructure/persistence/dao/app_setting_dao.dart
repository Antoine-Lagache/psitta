import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Persists small application settings and streak state as key/value pairs.
class AppSettingDao {
  final sqlite.SqliteDatabase database;

  AppSettingDao(this.database);

  Future<String?> get(String key) async {
    final rows = await database.getAll('SELECT value FROM app_setting WHERE key = ?', [
      key,
    ]);
    return rows.isEmpty ? null : rows.single['value'] as String;
  }

  Future<void> set(String key, String value) async {
    await database.execute(
      'INSERT INTO app_setting (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  Future<void> setAll(Map<String, String> values) async {
    await database.writeTransaction((txn) async {
      for (final entry in values.entries) {
        await txn.execute(
          'INSERT INTO app_setting (key, value) VALUES (?, ?) '
          'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
          [entry.key, entry.value],
        );
      }
    });
  }
}
