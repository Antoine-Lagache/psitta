// This file contains utility functions
// for safely converting dynamic values to specific numeric types
// (double, int, bool) with fallback options and error handling.

double safeToDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  try {
    return double.parse(value.toString());
  } catch (_) {
    return fallback;
  }
}

int safeToInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  try {
    return int.parse(value.toString());
  } catch (_) {
    return fallback;
  }
}

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
