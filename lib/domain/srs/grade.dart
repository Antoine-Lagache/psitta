/// Four ratings accepted by FSRS when reviewing a card.
enum Grade {
  again(1),
  hard(2),
  good(3),
  easy(4);

  /// Stable persisted value matching `fsrs.Rating.value`.
  final int value;

  const Grade(this.value);

  /// Again is the only FSRS rating that records a failed recall.
  bool get isFail => this == Grade.again;

  int toInt() => value;

  static Grade fromInt(int value) {
    return switch (value) {
      1 => Grade.again,
      2 => Grade.hard,
      3 => Grade.good,
      4 => Grade.easy,
      _ => throw ArgumentError('Invalid grade value: $value'),
    };
  }
}
