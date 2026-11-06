/// Current corpus counts classified by their FSRS progress.
class ExerciseProgressCounts {
  final int notStarted;
  final int started;
  final int mastered;

  const ExerciseProgressCounts({
    required this.notStarted,
    required this.started,
    required this.mastered,
  });
}
