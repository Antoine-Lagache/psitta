/// Current corpus counts classified by their FSRS progress.
typedef ExerciseTypeProgressCounts = ({int notStarted, int started, int mastered});

class ExerciseProgressCounts {
  final int notStarted;
  final int started;
  final int mastered;
  final Map<String, ExerciseTypeProgressCounts> byType;

  const ExerciseProgressCounts({
    required this.notStarted,
    required this.started,
    required this.mastered,
    this.byType = const {},
  });
}
