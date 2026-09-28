import 'package:flutter/material.dart';
import 'package:psitta/domain/srs/grade.dart';

/// Displays one side of the current exercise and its available actions.
class LearningContent extends StatelessWidget {
  final Widget front;
  final Widget back;
  final bool showingAnswer;
  final bool interactionEnabled;
  final Grade? selectedGrade;
  final List<Grade> allowedGrades;
  final Map<Grade, Duration> previewIntervals;
  final VoidCallback onRevealAnswer;
  final ValueChanged<Grade> onGradeSelected;
  final VoidCallback onToggleSide;
  final VoidCallback onCancelAnswer;
  final VoidCallback onNextExercise;

  const LearningContent({
    required this.front,
    required this.back,
    required this.showingAnswer,
    required this.interactionEnabled,
    required this.selectedGrade,
    required this.allowedGrades,
    required this.previewIntervals,
    required this.onRevealAnswer,
    required this.onGradeSelected,
    required this.onToggleSide,
    required this.onCancelAnswer,
    required this.onNextExercise,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _buildCard(context),
            const SizedBox(height: 20),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 280),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSideLabel(context),
              const SizedBox(height: 24),
              Center(child: _buildVisibleSide()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideLabel(BuildContext context) {
    return Text(
      showingAnswer ? 'Answer' : 'Question',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: const Color(0xFF616161),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildVisibleSide() {
    return KeyedSubtree(
      key: ValueKey(showingAnswer),
      child: showingAnswer ? back : front,
    );
  }

  Widget _buildActions() {
    if (selectedGrade != null) {
      return _buildSelectedAnswerActions(selectedGrade!);
    }
    if (!showingAnswer) {
      return _buildRevealButton();
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final grade in allowedGrades) _buildGradeButton(grade),
      ],
    );
  }

  Widget _buildRevealButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: interactionEnabled ? onRevealAnswer : null,
        child: const Text('Show answer'),
      ),
    );
  }

  Widget _buildSelectedAnswerActions(Grade grade) {
    return Column(
      children: [
        Text('${_gradeLabel(grade)} selected'),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: interactionEnabled ? onToggleSide : null,
              child: Text(showingAnswer ? 'Show question' : 'Show answer'),
            ),
            OutlinedButton(
              onPressed: interactionEnabled ? onCancelAnswer : null,
              child: const Text('Cancel answer'),
            ),
            FilledButton(
              onPressed: interactionEnabled ? onNextExercise : null,
              child: const Text('Next exercise'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeButton(Grade grade) {
    final interval = previewIntervals[grade];
    if (interval == null) {
      throw StateError('Missing preview interval for ${grade.name}');
    }

    return OutlinedButton(
      onPressed: interactionEnabled ? () => onGradeSelected(grade) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_gradeLabel(grade)),
            const SizedBox(height: 2),
            Text(_formatInterval(interval)),
          ],
        ),
      ),
    );
  }

  String _gradeLabel(Grade grade) {
    return switch (grade) {
      Grade.again => 'Again',
      Grade.hard => 'Hard',
      Grade.medium => 'Medium',
      Grade.good => 'Good',
      Grade.easy => 'Easy',
    };
  }

  String _formatInterval(Duration duration) {
    if (duration < const Duration(minutes: 1)) {
      return duration == Duration.zero ? 'Now' : '${duration.inSeconds}s';
    }
    if (duration < const Duration(hours: 1)) {
      return '${duration.inMinutes}m';
    }
    if (duration < const Duration(days: 1)) {
      return '${duration.inHours}h';
    }
    return '${duration.inDays}d';
  }
}
