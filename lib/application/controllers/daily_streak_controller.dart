import 'package:psitta/infrastructure/persistence/dao/app_setting_dao.dart';

class DailyStreakController {
  static const _countKey = 'statistics.daily_streak.count';
  static const _dateKey = 'statistics.daily_streak.local_date';
  static const _offsetKey = 'statistics.daily_streak.utc_offset_minutes';
  static const _instantKey = 'statistics.daily_streak.last_activity_utc';

  final AppSettingDao _settings;

  DailyStreakController(this._settings);

  Future<int> getCurrent([DateTime? now]) async => (await getStatus(now)).count;

  Future<({int count, bool activityToday})> getStatus([DateTime? now]) async {
    final count = int.tryParse(await _settings.get(_countKey) ?? '') ?? 0;
    final lastDate = await _settings.get(_dateKey);
    final lastOffset = int.tryParse(await _settings.get(_offsetKey) ?? '');
    final lastInstant = DateTime.tryParse(await _settings.get(_instantKey) ?? '');
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = _dateKeyOf(localNow);
    final activityToday =
        count > 0 && lastInstant != null && _dateKeyOf(lastInstant.toLocal()) == today;

    if (count == 0 || lastDate == null) {
      return (count: 0, activityToday: false);
    }
    if (today == lastDate) return (count: count, activityToday: activityToday);

    final elapsedSinceActivity = lastInstant == null
        ? null
        : localNow.difference(lastInstant);
    if (lastOffset != localNow.timeZoneOffset.inMinutes &&
        elapsedSinceActivity != null &&
        !elapsedSinceActivity.isNegative &&
        elapsedSinceActivity <= const Duration(hours: 48)) {
      return (count: count, activityToday: activityToday);
    }
    final currentCount = _dateOrdinal(today) - _dateOrdinal(lastDate) == 1 ? count : 0;
    return (count: currentCount, activityToday: activityToday);
  }

  /// Counts local calendar days; an offset change re-anchors without a reset.
  Future<void> recordActivity(DateTime instant) async {
    final local = instant.toLocal();
    final date = _dateKeyOf(local);
    final offset = local.timeZoneOffset.inMinutes;
    final previousDate = await _settings.get(_dateKey);
    final previousOffset = int.tryParse(await _settings.get(_offsetKey) ?? '');
    final previousInstant = DateTime.tryParse(await _settings.get(_instantKey) ?? '');
    var count = int.tryParse(await _settings.get(_countKey) ?? '') ?? 0;

    if (previousDate == null || count == 0) {
      count = 1;
    } else if (date != previousDate) {
      final elapsedDays = _dateOrdinal(date) - _dateOrdinal(previousDate);
      if (previousOffset != offset) {
        // A timezone/DST transition can skip or repeat a civil date. Preserve
        // the streak for a recent activity and establish the current timezone's
        // new date anchor. A long absence still breaks the streak.
        final elapsed = previousInstant == null
            ? null
            : instant.toUtc().difference(previousInstant.toUtc());
        if (elapsed != null &&
            !elapsed.isNegative &&
            elapsed <= const Duration(hours: 48)) {
          count++;
        } else {
          count = 1;
        }
      } else if (elapsedDays == 1) {
        count++;
      } else if (elapsedDays != 1) {
        count = 1;
      }
    }

    await _settings.setAll({
      _countKey: '$count',
      _dateKey: date,
      _offsetKey: '$offset',
      _instantKey: instant.toUtc().toIso8601String(),
    });
  }

  static String _dateKeyOf(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static int _dateOrdinal(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }
}
