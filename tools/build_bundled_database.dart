import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/psitta_sqlite_open_factory.dart';
import 'package:psitta/infrastructure/persistence/release/release_content_importer.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Run with flutter test tools/build_bundled_database.dart.
/// Uses the real migrations, importer, DAOs, and initial domain state.
void main() {
  test('build the bundled SQLite snapshot', () async {
    const outputPath = String.fromEnvironment(
      'SEED_OUTPUT',
      defaultValue: 'assets/database',
    );
    final output = await Directory(outputPath).create(recursive: true);
    final work = await Directory.systemTemp.createTemp('psitta_seed_');
    final database = sqlite.SqliteDatabase.withFactory(
      PsittaSqliteOpenFactory(path: '${work.path}/build.db'),
    );
    final timer = Stopwatch()..start();
    try {
      await database.initialize();
      await createMigrationRunner().migrate(database);
      await ReleaseContentImporter(
        database,
        loadAsset: (path) => File(path).readAsBytes(),
      ).importIfEmpty();
      expect((await database.get('PRAGMA integrity_check')).values.single, 'ok');
      expect(await database.getAll('PRAGMA foreign_key_check'), isEmpty);
      final version = (await database.get('PRAGMA user_version'))['user_version'];
      // VACUUM INTO produces a standalone snapshot including committed WAL data.
      final snapshot = '${work.path}/snapshot.db';
      await database.writeLock((context) => context.execute('VACUUM INTO ?', [snapshot]));
      final bytes = await File(snapshot).readAsBytes();
      final compressed = gzip.encode(bytes);
      final sourceManifest = await File(
        'assets/content/v0_1/manifest.json',
      ).readAsBytes();
      final metadata = {
        'format_version': 1,
        'database_version': version,
        'database_bytes': bytes.length,
        'database_sha256': sha256.convert(bytes).toString(),
        'gzip_sha256': sha256.convert(compressed).toString(),
        'content_manifest_sha256': sha256.convert(sourceManifest).toString(),
        'counts': (jsonDecode(utf8.decode(sourceManifest)) as Map)['counts'],
      };
      await File('${output.path}/psitta.db.gz').writeAsBytes(compressed, flush: true);
      await File('${output.path}/manifest.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(metadata)}\n',
        flush: true,
      );
      // ignore: avoid_print
      print(
        'Built ${bytes.length} bytes (${compressed.length} compressed) in ${timer.elapsedMilliseconds} ms',
      );
    } finally {
      await database.close();
      await work.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
