import 'package:psitta/domain/sessions/session_type.dart';

/// Counts displayed for one session type on the application home screen.
///
/// For a new session, the counts describe the exercises that would be loaded
/// with the current configuration limits. For an active session, they describe
/// its persisted snapshot and exclude completed exercises.
class SessionOverview {
  final SessionType sessionType;
  final int newExerciseCount;
  final int reviewExerciseCount;
  final bool hasActiveSession;

  SessionOverview({
    required this.sessionType,
    required this.newExerciseCount,
    required this.reviewExerciseCount,
    required this.hasActiveSession,
  });
}
