import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/infrastructure/persistence/database/migration_registry.dart';
import 'package:psitta/infrastructure/persistence/database/migration_runner.dart';
import 'package:psitta/infrastructure/persistence/database/migrations/database_migration.dart';
import 'package:psitta/infrastructure/persistence/database/sqlite_database.dart';
import 'package:psitta/infrastructure/persistence/release/bundled_database_installer.dart';
import 'package:psitta/infrastructure/persistence/release/release_content_importer.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'support/persistence_test_database.dart';

class _NextMigration implements DatabaseMigration {
  @override
  int get version => createMigrationRunner().latestVersion + 1;

  @override
  Future<void> migrate(sqlite.SqliteWriteContext database) async {
    await database.execute('CREATE TABLE migration_probe (id INTEGER PRIMARY KEY)');
  }
}

void main() {
  late Directory directory;
  late String path;
  late SqliteDatabase owner;
  final installer = BundledDatabaseInstaller(loadAsset: (p) => File(p).readAsBytes());

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('psitta_install_test_');
    path = '${directory.path}/psitta.db';
    owner = SqliteDatabase(path: path, installer: installer);
  });
  tearDown(() async {
    await owner.close();
    await directory.delete(recursive: true);
  });

  test('bundled snapshot equals the current migrations and full importer', () async {
    final reference = await PersistenceTestDatabase.create();
    try {
      final timer = Stopwatch()..start();
      await ReleaseContentImporter(
        reference.database,
        loadAsset: (p) => File(p).readAsBytes(),
      ).importIfEmpty();
      final importMs = timer.elapsedMilliseconds;
      timer.reset();
      final installed = await owner.open();
      final installMs = timer.elapsedMilliseconds;
      final schema = await reference.database.getAll(
        "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY type, name",
      );
      expect(
        await installed.getAll(
          "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY type, name",
        ),
        schema,
        reason: 'Regenerate the snapshot after schema changes',
      );
      for (final row in schema.where((row) => row['type'] == 'table')) {
        final name = row['name'] as String;
        final quoted = '"${name.replaceAll('"', '""')}"';
        final columns = await reference.database.getAll('PRAGMA table_info($quoted)');
        final order = columns
            .map((column) => '"${(column['name'] as String).replaceAll('"', '""')}"')
            .join(', ');
        expect(
          await installed.getAll('SELECT * FROM $quoted ORDER BY $order'),
          await reference.database.getAll('SELECT * FROM $quoted ORDER BY $order'),
          reason: 'Regenerate the snapshot: $name differs',
        );
      }
      final metadata =
          jsonDecode(await File('assets/database/manifest.json').readAsString()) as Map;
      expect(metadata['database_version'], createMigrationRunner().latestVersion);
      expect(
        metadata['content_manifest_sha256'],
        sha256
            .convert(await File('assets/content/v0_1/manifest.json').readAsBytes())
            .toString(),
      );
      expect((await installed.get('PRAGMA integrity_check')).values.single, 'ok');
      expect(await installed.getAll('PRAGMA foreign_key_check'), isEmpty);
      expect((await installed.get('PRAGMA foreign_keys')).values.single, 1);
      // Informational measurement only; device-specific timing is not a gate.
      // ignore: avoid_print
      print('Full import: $importMs ms; snapshot install + open: $installMs ms');
    } finally {
      await reference.dispose();
    }
  });

  test('concurrent opens share a connection and upgrades preserve progression', () async {
    final connections = await Future.wait([owner.open(), owner.open()]);
    expect(identical(connections.first, connections.last), isTrue);
    await connections.first.execute(
      'UPDATE srs_state SET interval = 987654 WHERE exercise_id = 1',
    );
    await connections.first.execute(
      "INSERT INTO exercise_history (exercise_id, grade, answered_at, status) VALUES (1, 2, '2026-10-16T00:00:00Z', 1)",
    );
    await owner.close();
    owner = SqliteDatabase(
      path: path,
      installer: BundledDatabaseInstaller(
        loadAsset: (_) => throw StateError('Must not read seed on existing installs'),
      ),
      migrationRunner: MigrationRunner(
        migrations: [...createMigrationRunner().migrations, _NextMigration()],
      ),
    );
    final upgraded = await owner.open();
    expect(
      (await upgraded.get('PRAGMA user_version')).values.single,
      _NextMigration().version,
    );
    expect(
      (await upgraded.get(
        'SELECT interval FROM srs_state WHERE exercise_id = 1',
      )).values.single,
      987654,
    );
    expect(
      (await upgraded.get('SELECT COUNT(*) FROM exercise_history')).values.single,
      1,
    );
    expect(await upgraded.getAll('SELECT * FROM migration_probe'), isEmpty);
  });

  test('a fresh snapshot can run a later schema migration', () async {
    owner = SqliteDatabase(
      path: path,
      installer: installer,
      migrationRunner: MigrationRunner(
        migrations: [...createMigrationRunner().migrations, _NextMigration()],
      ),
    );
    final db = await owner.open();
    expect((await db.get('PRAGMA user_version')).values.single, _NextMigration().version);
    expect(await db.getAll('SELECT * FROM migration_probe'), isEmpty);
    expect((await db.get('SELECT COUNT(*) FROM exercise')).values.single, greaterThan(0));
  });

  test('unsupported snapshot and orphaned journals do not publish a database', () async {
    await expectLater(
      installer.installIfMissing(path, latestVersion: 0),
      throwsFormatException,
    );
    expect(await File(path).exists(), isFalse);
    await File('$path-wal').writeAsString('orphan');
    await expectLater(
      installer.installIfMissing(
        path,
        latestVersion: createMigrationRunner().latestVersion,
      ),
      throwsStateError,
    );
    expect(await File(path).exists(), isFalse);
    expect(await File('$path-wal').readAsString(), 'orphan');
  });

  test('corruption publishes no database; interrupted copy can be retried', () async {
    final corrupt = BundledDatabaseInstaller(
      loadAsset: (p) async {
        final bytes = await File(p).readAsBytes();
        if (p.endsWith('.gz')) bytes[0] ^= 1;
        return bytes;
      },
    );
    await expectLater(
      corrupt.installIfMissing(
        path,
        latestVersion: createMigrationRunner().latestVersion,
      ),
      throwsFormatException,
    );
    expect(await File(path).exists(), isFalse);
    await File('$path.installing').writeAsString('interrupted copy');
    expect(
      await installer.installIfMissing(
        path,
        latestVersion: createMigrationRunner().latestVersion,
      ),
      isTrue,
    );
    expect(await File('$path.installing').exists(), isFalse);
    await owner.open();
  });

  test('a newer schema is rejected without replacing the existing database', () async {
    final db = await owner.open();
    await db.execute('PRAGMA user_version = 100000');
    await owner.close();
    await expectLater(owner.open(), throwsStateError);
    expect(await File(path).exists(), isTrue);
  });

  test('existing empty database uses the recoverable legacy importer', () async {
    final legacy = await PersistenceTestDatabase.create();
    try {
      final existing = SqliteDatabase(
        path: legacy.path,
        installer: BundledDatabaseInstaller(
          loadAsset: (_) => throw StateError('Existing database must not be replaced'),
        ),
      );
      try {
        final db = await existing.open();
        expect(
          await ReleaseContentImporter(
            db,
            loadAsset: (p) => File(p).readAsBytes(),
          ).importIfEmpty(),
          isTrue,
        );
      } finally {
        await existing.close();
      }
    } finally {
      await legacy.dispose();
    }
  });
}
