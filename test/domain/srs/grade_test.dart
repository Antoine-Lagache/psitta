import 'package:psitta/domain/srs/grade.dart';
import 'package:test/test.dart';

void main() {
  test('uses stable FSRS rating values and parses them explicitly', () {
    expect(Grade.values.map((grade) => grade.toInt()), [1, 2, 3, 4]);
    expect([1, 2, 3, 4].map(Grade.fromInt), [
      Grade.again,
      Grade.hard,
      Grade.good,
      Grade.easy,
    ]);
    expect(() => Grade.fromInt(0), throwsArgumentError);
    expect(() => Grade.fromInt(5), throwsArgumentError);
  });

  test('only Again is a failed recall', () {
    expect(Grade.again.isFail, isTrue);
    expect(Grade.hard.isFail, isFalse);
    expect(Grade.good.isFail, isFalse);
    expect(Grade.easy.isFail, isFalse);
  });
}
