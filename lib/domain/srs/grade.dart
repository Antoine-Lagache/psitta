/// all possible grades for an exercise in a SRS session.
/// Grade.q corresponds to the quality of the answer in the SM-2 algorithm.
/// The SM-2 algorithm takes a grade between 0 and 5.
enum Grade {
  again(0), // same as Again in Anki
  hard(2), // Doesn't exist in Anki
  medium(3), // same as Hard in Anki
  good(4), // same as Good in Anki
  easy(5); // same as Easy in Anki

  final int q;
  bool get isFail => q < 3; // q < 3 <=> Fail

  const Grade(this.q);

  int toInt() => q;
}
