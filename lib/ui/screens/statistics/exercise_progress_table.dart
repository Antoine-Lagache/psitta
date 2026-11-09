import 'package:flutter/material.dart';
import 'package:psitta/application/models/statistics/exercise_progress_counts.dart';

/// Renders the per-exercise-type counts or percentages in the statistics page.
class ExerciseProgressTable extends StatelessWidget {
  final ExerciseProgressCounts progressCounts;
  final bool showPercentages;

  const ExerciseProgressTable({
    required this.progressCounts,
    required this.showPercentages,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const types = [
      (label: 'Words', key: 'word'),
      (label: 'Sentences', key: 'sentence'),
      (label: 'Kana', key: 'character'),
    ];
    const zero = (notStarted: 0, started: 0, mastered: 0);

    return Column(
      children: [
        _buildProgressRow(
          context,
          'Exercise type',
          'New',
          'Started',
          'Mastered',
          'Total',
          isHeader: true,
        ),
        const SizedBox(height: 16),
        for (final type in types) ...[
          _buildProgressValues(
            context,
            type.label,
            progressCounts.byType[type.key] ?? zero,
          ),
          const SizedBox(height: 18),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mastered means FSRS stability above 30 days.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressValues(
    BuildContext context,
    String label,
    ExerciseTypeProgressCounts counts,
  ) {
    final total = counts.notStarted + counts.started + counts.mastered;
    String format(int count) {
      if (!showPercentages) return '$count';
      if (total == 0) return '—';
      return '${(count * 100 / total).toStringAsFixed(1)}%';
    }

    return _buildProgressRow(
      context,
      label,
      format(counts.notStarted),
      format(counts.started),
      format(counts.mastered),
      showPercentages ? (total == 0 ? '—' : '100.0%') : '$total',
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    String label,
    String notStarted,
    String started,
    String mastered,
    String total, {
    bool isHeader = false,
  }) {
    final style = isHeader
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          )
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: style)),
        _buildProgressCell(notStarted, style),
        _buildProgressCell(started, style),
        _buildProgressCell(mastered, style),
        _buildProgressCell(total, style, emphasize: true),
      ],
    );
  }

  Widget _buildProgressCell(String value, TextStyle? style, {bool emphasize = false}) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: emphasize ? style?.copyWith(fontWeight: FontWeight.w700) : style,
        ),
      ),
    );
  }

}
