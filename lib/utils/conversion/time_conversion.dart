import 'package:psitta/utils/conversion/safe_numeric_conversion.dart';

/// Parses a persisted UTC timestamp and converts it to local time.
DateTime? safeParseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return DateTime.parse(value).toLocal();
  } catch (_) {
    return null;
  }
}

/// Serializes [date] as an ISO-8601 UTC timestamp.
///
/// SQLite compares these values lexicographically. Dart omits zero
/// microseconds, so ordering can differ within one millisecond; this discrepancy
/// is acceptable for the MVP.
String? toIsoUtc(DateTime? date) {
  return date?.toUtc().toIso8601String();
}

/// Reads a non-negative microsecond count as a duration.
Duration safeToDuration(dynamic value, {Duration fallback = Duration.zero}) {
  if (value == null) return fallback;
  final intVal = safeToInt(value, fallback: -1);
  return intVal >= 0 ? Duration(microseconds: intVal) : fallback;
}

/// Serializes [duration] as a microsecond count.
int safeFromDuration(Duration duration) {
  return duration.inMicroseconds;
}

double durationToDays(Duration duration) =>
    duration.inMicroseconds / Duration.microsecondsPerDay;

Duration daysToduration(double days) {
  return Duration(microseconds: (days * Duration.microsecondsPerDay).round());
}
