class SRS {
  DateTime nextReview;
  int repetitionCount;
  double easeFactor;
  Duration interval;
  DateTime lastReview;
  List<int> history;

  SRS({
    DateTime? nextReview,
    this.repetitionCount = 0,
    this.easeFactor = 2.5,
    this.interval = const Duration(days: 1),
    DateTime? lastReview,
    this.history = const [],
  })  : nextReview = nextReview ?? DateTime.now(),
        lastReview = lastReview ?? DateTime.now();
}