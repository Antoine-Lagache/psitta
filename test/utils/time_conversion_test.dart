import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:test/test.dart';

void main() {
  test('dates are stored in UTC and restored in local time', () {
    final localDate = DateTime(2026, 9, 3, 21, 30);

    final persisted = toIsoUtc(localDate);
    final restored = safeParseDate(persisted);

    expect(persisted, endsWith('Z'));
    expect(restored?.isUtc, isFalse);
    expect(restored?.toUtc(), localDate.toUtc());
  });
}
