/// Portable identity of an immutable or locally mutable bank commit.
///
/// The UID also identifies the exact bank state represented by the commit.
final class CommitUid {
  final String value;

  CommitUid(String value) : value = _validate(value);

  static String _validate(String value) {
    if (value.isEmpty || value.trim() != value) {
      throw ArgumentError.value(
        value,
        'value',
        'Must not be empty or have surrounding whitespace',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) => other is CommitUid && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
