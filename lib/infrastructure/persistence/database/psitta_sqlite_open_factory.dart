import 'package:sqlite_async/native.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// Configures every native SQLite connection used by Psitta.
final class PsittaSqliteOpenFactory extends NativeSqliteOpenFactory {
  PsittaSqliteOpenFactory({required super.path, super.sqliteOptions});

  @override
  List<String> pragmaStatements(SqliteOpenOptions options) {
    return [
      ...super.pragmaStatements(options),
      'PRAGMA foreign_keys = ON',
    ];
  }
}
