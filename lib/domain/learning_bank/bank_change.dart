import 'dart:convert';

import 'bank_change_ref.dart';

/// One change to one logical entity, stored as a typed JSON payload.
///
/// The operation types and payload schemas are intentionally left to the
/// change-model design; they must identify their target inside the payload.
final class BankChange {
  final BankChangeRef ref;
  final BankChangeRef? previousChangeRef;
  final String changeType;
  final Map<String, Object?> payload;

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
  }

  static Map<String, Object?> _freezeJsonMap(Map<String, Object?> value) {
    final decoded = jsonDecode(jsonEncode(value));
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
