import 'package:flutter/material.dart';
import 'package:psitta/application/models/statistics/exercise_progress_counts.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';

typedef _Metric = ({String label, String value});
typedef _BreakdownEntry = ({String label, int value});

enum _StatisticsSection {
  today('Today'),
  allTime('All time'),
  learningProgress('Exercise progress'),
  sessions('Completed sessions'),
  grades('Answers by grade');

  const _StatisticsSection(this.label);

  final String label;
}

/// Presents statistics in unframed sections with a section jump menu.
class StatisticsContent extends StatefulWidget {
  final SessionStatistics sessionStatistics;
  final ExerciseStatistics exerciseStatistics;
  final SessionStatistics todaySessionStatistics;
  final ExerciseStatistics todayExerciseStatistics;
  final RefreshCallback onRefresh;
  final ExerciseProgressCounts progressCounts;
  final int dailyStreak;

  const StatisticsContent({
    required this.sessionStatistics,
    required this.exerciseStatistics,
    required this.todaySessionStatistics,
    required this.todayExerciseStatistics,
    required this.onRefresh,
    this.progressCounts = const ExerciseProgressCounts(
      notStarted: 0,
      started: 0,
      mastered: 0,
    ),
    this.dailyStreak = 0,
    super.key,
  });

  @override
  State<StatisticsContent> createState() => _StatisticsContentState();
}

class _StatisticsContentState extends State<StatisticsContent> {
  final _sectionKeys = {
    for (final section in _StatisticsSection.values) section: GlobalKey(),
  };

  void _jumpToSection(_StatisticsSection section) {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      alignment: 0.04,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            children: [
              ..._buildHeader(context),
              const SizedBox(height: 28),
              _buildSection(
                context,
                _StatisticsSection.today,
                _buildOverview(
                  context,
                  sessions: widget.todaySessionStatistics,
                  exercises: widget.todayExerciseStatistics,
                ),
              ),
              _buildSection(
                context,
                _StatisticsSection.allTime,
                _buildOverview(
                  context,
                  sessions: widget.sessionStatistics,
                  exercises: widget.exerciseStatistics,
                ),
              ),
              _buildSection(
                context,
                _StatisticsSection.learningProgress,
                _buildExerciseProgress(context),
              ),
              _buildSection(
                context,
                _StatisticsSection.sessions,
                _buildSessionBreakdown(context),
              ),
              _buildSection(
                context,
                _StatisticsSection.grades,
                _buildGradeBreakdown(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeader(BuildContext context) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Statistics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          PopupMenuButton<_StatisticsSection>(
            tooltip: 'Move to a section',
            onSelected: _jumpToSection,
            itemBuilder: (context) => [
              for (final section in _StatisticsSection.values)
                PopupMenuItem(value: section, child: Text(section.label)),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.menu), SizedBox(width: 6), Text('Sections')],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Your learning activity today and overall.',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF616161)),
      ),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFE87524), size: 48),
          const SizedBox(width: 12),
          Text(
            '${widget.dailyStreak}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.dailyStreak == 1 ? 'day streak' : 'days streak',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildSection(BuildContext context, _StatisticsSection section, Widget content) {
    return Padding(
      key: _sectionKeys[section],
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context, {
    required SessionStatistics sessions,
    required ExerciseStatistics exercises,
  }) {
    final metrics = _overviewMetrics(sessions, exercises);
    return Column(
      children: [
        _buildMetricRow(context, metrics[0], metrics[1]),
        const SizedBox(height: 20),
        _buildMetricRow(context, metrics[2], metrics[3]),
      ],
    );
  }

  List<_Metric> _overviewMetrics(
    SessionStatistics sessions,
    ExerciseStatistics exercises,
  ) {
    return [
      (label: 'Sessions completed', value: '${sessions.numberOfSessions}'),
      (label: 'Completed session time', value: _formatDuration(sessions.totalTimeSpent)),
      (label: 'Answers recorded', value: '${exercises.totalNumberAnswers}'),
      (label: 'Exercises completed', value: '${sessions.numberOfExercisesCompleted}'),
    ];
  }

  Widget _buildMetricRow(BuildContext context, _Metric left, _Metric right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _StatisticMetric(metric: left)),
        const SizedBox(width: 20),
        Expanded(child: _StatisticMetric(metric: right)),
      ],
    );
  }

  Widget _buildExerciseProgress(BuildContext context) {
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
          isHeader: true,
        ),
        const SizedBox(height: 14),
        for (final type in types) ...[
          _buildProgressRow(
            context,
            type.label,
            (widget.progressCounts.byType[type.key] ?? zero).notStarted.toString(),
            (widget.progressCounts.byType[type.key] ?? zero).started.toString(),
            (widget.progressCounts.byType[type.key] ?? zero).mastered.toString(),
          ),
          const SizedBox(height: 14),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mastered means FSRS stability above 30 days.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF616161)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    String label,
    String notStarted,
    String started,
    String mastered, {
    bool isHeader = false,
  }) {
    final style = isHeader
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF616161),
            fontWeight: FontWeight.w600,
          )
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Expanded(flex: 3, child: Text(label, style: style)),
        Expanded(
          child: Text(notStarted, textAlign: TextAlign.end, style: style),
        ),
        Expanded(
          child: Text(started, textAlign: TextAlign.end, style: style),
        ),
        Expanded(
          child: Text(mastered, textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }

  Widget _buildSessionBreakdown(BuildContext context) {
    return _buildBreakdown(context, [
      (
        label: 'Words',
        value: widget.sessionStatistics.getNumberOfSessionsBySessionType(
          SessionType.wordSession,
        ),
      ),
      (
        label: 'Sentences',
        value: widget.sessionStatistics.getNumberOfSessionsBySessionType(
          SessionType.sentenceSession,
        ),
      ),
      (
        label: 'Kana',
        value: widget.sessionStatistics.getNumberOfSessionsBySessionType(
          SessionType.characterSession,
        ),
      ),
    ]);
  }

  Widget _buildGradeBreakdown(BuildContext context) {
    return _buildBreakdown(context, [
      (
        label: 'Again',
        value: widget.exerciseStatistics.getNumberOfAnswersByGrade(Grade.again),
      ),
      (
        label: 'Hard',
        value: widget.exerciseStatistics.getNumberOfAnswersByGrade(Grade.hard),
      ),
      (
        label: 'Good',
        value: widget.exerciseStatistics.getNumberOfAnswersByGrade(Grade.good),
      ),
      (
        label: 'Easy',
        value: widget.exerciseStatistics.getNumberOfAnswersByGrade(Grade.easy),
      ),
    ]);
  }

  Widget _buildBreakdown(BuildContext context, List<_BreakdownEntry> entries) {
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: Text(entry.label)),
                Text(
                  '${entry.value}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '0 min';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return duration.inMinutes == 0 ? '<1 min' : '$minutes min';
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }
}

class _StatisticMetric extends StatelessWidget {
  final _Metric metric;

  const _StatisticMetric({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF616161)),
        ),
      ],
    );
  }
}
