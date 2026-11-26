import 'dart:convert';

import '../identity/entity_id.dart';

/// One change to one logical entity, stored as a typed JSON payload.
///
/// The operation identifies the entity kind; the payload identifies its target.
final class BankChange {
  final BankChangeRef ref;
  final BankChangeRef? previousChangeRef;
  final String changeType;
  final Map<String, Object?> payload;
  late final (String, Object, String) entityIdentity;

  BankChange({
    required this.ref,
    required this.previousChangeRef,
    required this.changeType,
    required Map<String, Object?> payload,
  }) : payload = _freezeJsonMap(payload) {
    if (previousChangeRef != null && previousChangeRef == ref) {
      throw ArgumentError('A change cannot be its own previous change');
    }
    if (previousChangeRef?.commitUid == ref.commitUid) {
      throw ArgumentError('A previous change must belong to an ancestor commit');
    }
    if (changeType.trim().isEmpty) {
      throw ArgumentError.value(changeType, 'changeType', 'Must not be empty');
    }
    entityIdentity = _resolveEntityIdentity();
  }

  (String, Object, String) _resolveEntityIdentity() => switch (changeType) {
    'add bank languages' => ('bank languages', '', ''),
    'add bank description' => ('bank description', '', ''),
    'add exercise' => ('exercise', _requiredInteger('exercise_id'), ''),
    'add sentence group' => ('sentence group', _requiredInteger('sentence_group_id'), ''),
    'add sentence' => ('sentence', _requiredInteger('sentence_id'), ''),
    'add content' => ('content', _requiredInteger('content_id'), ''),
    'add media' || 'remove media' => ('media', _requiredId('sha256'), ''),
    'add setting' ||
    'update setting' => ('setting', _requiredId('profile'), _requiredId('key')),
    _ => throw ArgumentError.value(changeType, 'changeType', 'Unsupported change type'),
  };

  int _requiredInteger(String key) {
    final value = payload[key];
    if (value is! int || value < 0) {
      throw ArgumentError.value(value, key, 'Must be a non-negative integer');
    }
    return value;
  }

  String _requiredId(String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError.value(value, key, 'Must be a non-empty string');
    }
    return value;
  }

  static Map<String, Object?> _freezeJsonMap(Map<String, Object?> value) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(jsonEncode(value));
    } on JsonUnsupportedObjectError {
      throw ArgumentError('A change payload must contain only JSON values');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('A change payload must encode as a JSON object');
    }
    return _freezeMap(decoded);
  }

  static Map<String, Object?> _freezeMap(Map<String, dynamic> value) =>
      Map<String, Object?>.unmodifiable({
        for (final entry in value.entries) entry.key: _freezeJson(entry.value),
      });

  static Object? _freezeJson(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Map<String, dynamic>) return _freezeMap(value);
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_freezeJson));
    }
    throw ArgumentError('A change payload must contain only JSON values');
  }
}
