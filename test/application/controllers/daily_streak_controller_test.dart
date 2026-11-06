import 'package:psitta/application/controllers/daily_streak_controller.dart';
import 'package:psitta/infrastructure/persistence/dao/app_setting_dao.dart';
import 'package:test/test.dart';

import '../../infrastructure/persistence/support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late DailyStreakController streak;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    streak = DailyStreakController(AppSettingDao(testDatabase.database));
  });

  tearDown(() => testDatabase.dispose());

  test('counts local civil days and resets after a skipped day', () async {
    await streak.recordActivity(DateTime(2026, 11, 1, 23));
    await streak.recordActivity(DateTime(2026, 11, 2, 1));
    expect(await streak.getCurrent(DateTime(2026, 11, 2, 12)), 2);
    expect(await streak.getCurrent(DateTime(2026, 11, 3, 12)), 2);
    expect(await streak.getCurrent(DateTime(2026, 11, 4, 12)), 0);
    await streak.recordActivity(DateTime(2026, 11, 4, 13));
    expect(await streak.getCurrent(DateTime(2026, 11, 4, 14)), 1);
  });

  test('repeated activity on the same local date does not increment', () async {
    await streak.recordActivity(DateTime(2026, 11, 1, 9));
    await streak.recordActivity(DateTime(2026, 11, 1, 21));
    expect(await streak.getCurrent(DateTime(2026, 11, 1, 22)), 1);
  });
}
