/// Identifies a change's logical target within a commit, not its SQL reference.
sealed class BankEntityIdentity<T> {
  final T value;

  const BankEntityIdentity(this.value);

  @override
  bool operator ==(Object other) =>
      other is BankEntityIdentity<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class ExerciseIdentity extends BankEntityIdentity<int> {
  const ExerciseIdentity(super.value);
}

final class ContentIdentity extends BankEntityIdentity<int> {
  const ContentIdentity(super.value);
}

final class SentenceIdentity extends BankEntityIdentity<int> {
  const SentenceIdentity(super.value);
}

final class SentenceGroupIdentity extends BankEntityIdentity<int> {
  const SentenceGroupIdentity(super.value);
}

final class MediaIdentity extends BankEntityIdentity<String> {
  const MediaIdentity(super.value);
}

final class SettingIdentity extends BankEntityIdentity<(String, String)> {
  const SettingIdentity(super.value);
}

final class BankLanguagesIdentity extends BankEntityIdentity<Null> {
  const BankLanguagesIdentity() : super(null);
}

final class BankDescriptionIdentity extends BankEntityIdentity<Null> {
  const BankDescriptionIdentity() : super(null);
}
