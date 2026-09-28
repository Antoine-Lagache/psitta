import 'dart:convert';

/// Decodes a JSON object, returning an empty map for null or invalid input.
Map<String, dynamic> safeJsonDecodeMap(String? jsonText) {
  if (jsonText == null) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    return decoded;
  } on Object {
    // This boundary helper deliberately collapses every conversion failure.
    return <String, dynamic>{};
  }
}

/// Decodes a JSON array, returning an empty list for null or invalid input.
List<dynamic> safeJsonDecodeList(String? jsonText) {
  if (jsonText == null) return <dynamic>[];
  try {
    final decoded = jsonDecode(jsonText) as List<dynamic>;
    return decoded;
  } on Object {
    // This boundary helper deliberately collapses every conversion failure.
    return <dynamic>[];
  }
}

/// Encodes [value], returning null when it is not JSON-serializable.
String? safeJsonEncode(Object? value) {
  try {
    return jsonEncode(value);
  } on Object {
    // This boundary helper deliberately collapses every conversion failure.
    return null;
  }
}

/// Decodes a JSON array and converts each element to a string.
List<String> safeJsonDecodeStringList(String? jsonText) {
  final list = safeJsonDecodeList(jsonText);
  return list.map((e) => e.toString()).toList();
}
