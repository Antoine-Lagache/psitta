import 'dart:convert';

// ------- conversion numérique -------

/// Convertit une valeur dynamique en double.
/// Retourne [fallback] si la conversion échoue.
double safeToDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  try {
    return double.parse(value.toString());
  } catch (_) {
    return fallback;
  }
}

/// Convertit une valeur dynamique en int.
/// Retourne [fallback] si la conversion échoue.
int safeToInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  try {
    return int.parse(value.toString());
  } catch (_) {
    return fallback;
  }
}

/// Convertie un dynamic en bool.
/// Retourne [fallback] si la conversion échoue.
bool safeToBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

// ------- Conversion temporelle -------

/// Parse une chaîne en DateTime.
/// Retourne null si [value] est null ou invalide.
DateTime? safeParseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final dt = DateTime.parse(value);
    return dt.isUtc ? dt : dt.toUtc();
  } catch (_) {
    return null;
  }
}

String? toIsoUtc(DateTime? date){
  return date?.toUtc().toIso8601String();
}

Duration safeToDuration(dynamic value, {Duration fallback = Duration.zero}) {
  if (value == null) return fallback;
  final intVal = safeToInt(value, fallback: -1);
  return intVal >= 0 ? Duration(milliseconds: intVal) : fallback;
}

int safeFromDuration(Duration duration) {
  return duration.inMilliseconds;
}

// ------- JSON --------

/// Décode du JSON en `Map<String, dynamic>`.
/// Retourne une map vide si la conversion échoue.
Map<String, dynamic> safeJsonDecodeMap(String? jsonText) {
  if (jsonText == null) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    return decoded;
    } catch (_) {
    return <String, dynamic>{};
  }
}

/// Décode du JSON en `List<dynamic>`.
/// Retourne une liste vide si la conversion échoue.
List<dynamic> safeJsonDecodeList(String? jsonText) {
  if (jsonText == null) return <dynamic>[];
  try {
    final decoded = jsonDecode(jsonText) as List<dynamic>;
    return decoded;
  } catch (_) {
    return <dynamic>[];
  }
}

/// Encode Du JSON en String?
/// Renvoie null si la conversion échoue
String? safeJsonEncode(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return null;
  }
}

// ------- Liste -------

/// Convertit un CSV en liste de String
List<String> safeJsonDecodeStringList(String? jsonText) {
  final list = safeJsonDecodeList(jsonText);
  return list.map((e) => e.toString()).toList();
}

