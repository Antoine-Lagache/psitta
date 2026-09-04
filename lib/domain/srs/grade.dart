/// Grades accepted by exercises during an SRS session.
/// [q] is the answer quality consumed by the SM-2 calculation.
/// The SM-2 algorithm takes a grade between 0 and 5.
enum Grade {
  again(0),
  hard(2),
  medium(3),
  good(4),
  easy(5);

  final int q;
  bool get isFail => q < 3;

  const Grade(this.q);

  int toInt() => q;

  static Grade fromInt(int q) {
    return switch (q) {
      0 => Grade.again,
      2 => Grade.hard,
      3 => Grade.medium,
      4 => Grade.good,
      5 => Grade.easy,
      _ => throw ArgumentError('Invalid grade value: $q'),
    };
  }
}
