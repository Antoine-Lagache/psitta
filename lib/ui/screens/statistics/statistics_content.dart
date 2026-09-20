import 'package:flutter/material.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';

typedef _Metric = ({String label, String value});
typedef _BreakdownEntry = ({String label, int value});

/// Presents the all-time statistics returned by the application layer.
class StatisticsContent extends StatelessWidget {
  final SessionStatistics sessionStatistics;
  final ExerciseStatistics exerciseStatistics;
  final RefreshCallback onRefresh;

  const StatisticsContent({
    required this.sessionStatistics,
    required this.exerciseStatistics,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: _buildScrollableContent(context),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            ..._buildHeader(context),
            const SizedBox(height: 28),
            _buildOverview(context),
            const SizedBox(height: 16),
            _buildSessionBreakdown(context),
            const SizedBox(height: 16),
            _buildGradeBreakdown(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeader(BuildContext context) {
    return [
      Text(
        'Statistics',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Your all-time learning activity.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFF616161),
        ),
      ),
    ];
  }

  Widget _buildOverview(BuildContext context) {
    final metrics = _overviewMetrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Overview'),
            const SizedBox(height: 16),
            _buildMetricRow(metrics[0], metrics[1]),
            const SizedBox(height: 12),
            _buildMetricRow(metrics[2], metrics[3]),
          ],
        ),
      ),
    );
  }

  List<_Metric> get _overviewMetrics {
    return [
      (
        label: 'Sessions completed',
        value: '${sessionStatistics.numberOfSessions}',
      ),
      (
        label: 'Completed session time',
        value: _formatDuration(sessionStatistics.totalTimeSpent),
      ),
      (
        label: 'Answers recorded',
        value: '${exerciseStatistics.totalNumberAnswers}',
      ),
      (
        label: 'Exercises completed',
        value: '${sessionStatistics.numberOfExercisesCompleted}',
      ),
    ];
  }

  Widget _buildMetricRow(_Metric left, _Metric right) {
    return Row(
      children: [
        Expanded(child: _StatisticMetric(metric: left)),
        const SizedBox(width: 12),
        Expanded(child: _StatisticMetric(metric: right)),
      ],
    );
  }

  Widget _buildSessionBreakdown(BuildContext context) {
    return _buildBreakdownCard(
      context,
      title: 'Completed sessions',
      entries: [
        (
          label: 'Words',
          value: sessionStatistics.getNumberOfSessionsBySessionType(
            SessionType.wordSession,
          ),
        ),
        (
          label: 'Sentences',
          value: sessionStatistics.getNumberOfSessionsBySessionType(
            SessionType.sentenceSession,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeBreakdown(BuildContext context) {
    return _buildBreakdownCard(
      context,
      title: 'Recorded answers by grade',
      entries: [
        for (final grade in Grade.values)
          (
            label: _gradeLabel(grade),
            value: exerciseStatistics.getNumberOfAnswersByGrade(grade),
          ),
      ],
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context, {
    required String title,
    required List<_BreakdownEntry> entries,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, title),
            const SizedBox(height: 12),
            for (var index = 0; index < entries.length; index++) ...[
              _buildBreakdownRow(context, entries[index]),
              if (index < entries.length - 1) const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, _BreakdownEntry entry) {
    return Row(
      children: [
        Expanded(child: Text(entry.label)),
        Text(
          '${entry.value}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return '0 min';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return duration.inMinutes == 0 ? '<1 min' : '$minutes min';
    }
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
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
}

class _StatisticMetric extends StatelessWidget {
  final _Metric metric;

  const _StatisticMetric({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}
