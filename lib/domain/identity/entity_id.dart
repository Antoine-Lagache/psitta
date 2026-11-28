import 'package:uuid/uuid.dart';

/// Value identity: equal values of different ID types are never equal.
sealed class EntityId<T> {
  final T value;

  const EntityId(this.value);

  @override
  bool operator ==(Object other) =>
      other is EntityId<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value.toString();
}

/// Local database identity. Zero is not a persisted row ID.
sealed class LocalId extends EntityId<int> {
  LocalId(int value) : super(_positive(value));

  static int _positive(int value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'value', 'Must be a persisted local ID');
    }
    return value;
  }
}

final class LearningBankId extends LocalId {
  LearningBankId(super.value);
}

final class ExerciseProgressId extends LocalId {
  ExerciseProgressId(super.value);
}

final class SessionResultId extends LocalId {
  SessionResultId(super.value);
}

final class ExerciseHistoryId extends LocalId {
  ExerciseHistoryId(super.value);
}

final class MediaId extends LocalId {
  MediaId(super.value);
}

/// Portable commit identity; provisional non-UUID values remain supported.
final class CommitUid extends EntityId<String> {
  CommitUid(String value) : super(_validate(value));

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

  factory CommitUid.generateUUID() => CommitUid(const Uuid().v4());
}

/// Identifies the exact change carrying an entity snapshot, not its lineage.
sealed class ChangeId extends EntityId<(CommitUid, int)> {
  ChangeId((CommitUid, int) value) : super(_validate(value));

  CommitUid get commitUid => value.$1;
  int get changeId => value.$2;

  static (CommitUid, int) _validate((CommitUid, int) value) {
    if (value.$2 < 0) {
      throw ArgumentError.value(value.$2, 'changeId', 'Must not be negative');
    }
    return value;
  }
}

final class BankChangeRef extends ChangeId {
  BankChangeRef({required CommitUid commitUid, required int changeId})
    : super((commitUid, changeId));
}

final class ExerciseId extends ChangeId {
  ExerciseId(super.value);
}

final class ContentId extends ChangeId {
  ContentId(super.value);
}

final class SentenceId extends ChangeId {
  SentenceId(super.value);
}

final class SentenceGroupId extends ChangeId {
  SentenceGroupId(super.value);
}

final class SentenceInstanceProgressId extends EntityId<(ExerciseProgressId, int)> {
  SentenceInstanceProgressId((ExerciseProgressId, int) value) : super(_validate(value));

  static (ExerciseProgressId, int) _validate((ExerciseProgressId, int) value) {
    if (value.$2 < 0) {
      throw ArgumentError.value(value.$2, 'sentenceId', 'Must not be negative');
    }
    return value;
  }

  ExerciseProgressId get exerciseProgressId => value.$1;
  int get sentenceId => value.$2;
}
