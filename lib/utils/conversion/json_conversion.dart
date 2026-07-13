import 'dart:convert';

// This file contains utility functions
// for safely converting JSON strings
// to and from specific types (Map, and list) with error handling

Map<String, dynamic> safeJsonDecodeMap(String? jsonText) {
  if (jsonText == null) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    return decoded;
  } catch (_) {
    return <String, dynamic>{};
  }
}

List<dynamic> safeJsonDecodeList(String? jsonText) {
  if (jsonText == null) return <dynamic>[];
  try {
    final decoded = jsonDecode(jsonText) as List<dynamic>;
    return decoded;
  } catch (_) {
    return <dynamic>[];
  }
}

String? safeJsonEncode(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return null;
  }
}

List<String> safeJsonDecodeStringList(String? jsonText) {
  final list = safeJsonDecodeList(jsonText);
  return list.map((e) => e.toString()).toList();
}
