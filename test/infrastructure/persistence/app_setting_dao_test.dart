import 'package:psitta/infrastructure/persistence/dao/app_setting_dao.dart';
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late AppSettingDao dao;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    dao = AppSettingDao(testDatabase.database);
  });

  tearDown(() => testDatabase.dispose());

  test('reads, inserts, updates, and atomically writes key-value settings', () async {
    expect(await dao.get('missing'), isNull);
    await dao.set('theme', 'dark');
    expect(await dao.get('theme'), 'dark');
    await dao.set('theme', 'light');
    await dao.setAll({'streak': '4', 'timezone': '+540'});
    expect(await dao.get('theme'), 'light');
    expect(await dao.get('streak'), '4');
    expect(await dao.get('timezone'), '+540');
  });
}
