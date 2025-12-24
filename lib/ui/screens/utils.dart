// screens_utils.dart
// Utility functions for screen displays.


/// returns a human-readable string for a Duration
String formatDuration(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} days';
  if (d.inHours >= 1) return '${d.inHours} hours';
  if (d.inMinutes >= 1) return '${d.inMinutes} min';
  return '< 1 min';
}