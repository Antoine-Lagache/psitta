import 'package:psitta/utils/conversion/safe_numeric_conversion.dart';

// This file contains utility functions
// for safely converting dynamic values to specific time-related types
// (DateTime, Duration) with fallback options and error handling.

DateTime? safeParseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final dt = DateTime.parse(value);
    return dt.isUtc ? dt : dt.toUtc();
  } catch (_) {
    return null;
  }
}

String? toIsoUtc(DateTime? date) {
  return date?.toUtc().toIso8601String();
}

Duration safeToDuration(dynamic value, {Duration fallback = Duration.zero}) {
  if (value == null) return fallback;
  final intVal = safeToInt(value, fallback: -1);
  return intVal >= 0 ? Duration(microseconds: intVal) : fallback;
}

int safeFromDuration(Duration duration) {
  return duration.inMicroseconds;
}

double durationToDays(Duration duration) =>
    duration.inMicroseconds / Duration.microsecondsPerDay;

Duration daysToduration(double days) {
  return Duration(microseconds: (days * Duration.microsecondsPerDay).round());
}
