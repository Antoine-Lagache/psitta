import 'package:flutter/material.dart';
import 'package:psitta/application/models/statistics/exercise_progress_counts.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';

typedef _Metric = ({String label, String value});
typedef _BreakdownEntry = ({String label, int value});

/// Presents statistics in navigable tabs and distinct, unbordered sections.
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
  bool _showPercentages = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _buildHeader(context),
          Container(
            color: _navigationColor(context),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Progress'),
                Tab(text: 'Sessions'),
                Tab(text: 'Grades'),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: TabBarView(
                  children: [
                    _buildPage(context, _buildOverviewPage(context)),
                    _buildPage(context, _buildProgressPage(context)),
                    _buildPage(context, _buildSessionsPage(context)),
                    _buildPage(context, _buildGradesPage(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your learning activity today and overall.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFFE87524),
                size: 42,
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.dailyStreak}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  widget.dailyStreak == 1 ? 'day streak' : 'days streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, List<Widget> sections) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: sections,
      ),
    );
  }

  List<Widget> _buildOverviewPage(BuildContext context) => [
    _buildSection(
      context,
      title: 'Today',
      child: _buildOverview(
        context,
        sessions: widget.todaySessionStatistics,
        exercises: widget.todayExerciseStatistics,
      ),
    ),
    const SizedBox(height: 16),
    _buildSection(
      context,
      title: 'All time',
      child: _buildOverview(
        context,
        sessions: widget.sessionStatistics,
        exercises: widget.exerciseStatistics,
      ),
    ),
  ];

  List<Widget> _buildProgressPage(BuildContext context) => [
    _buildSection(
      context,
      title: 'Exercise progress',
      key: const ValueKey('statistics-progress-section'),
      action: IconButton(
        tooltip: _showPercentages ? 'Show counts' : 'Show percentages',
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(() => _showPercentages = !_showPercentages),
        icon: Icon(_showPercentages ? Icons.numbers : Icons.percent),
      ),
      child: _buildExerciseProgress(context),
    ),
  ];

  List<Widget> _buildSessionsPage(BuildContext context) => [
    _buildSection(
      context,
      title: 'Completed sessions',
      child: _buildBreakdown(context, _sessionEntries()),
    ),
  ];

  List<Widget> _buildGradesPage(BuildContext context) => [
    _buildSection(
      context,
      title: 'Recorded answers by grade',
      child: _buildBreakdown(context, _gradeEntries()),
    ),
  ];

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? action,
    Key? key,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navigationColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Color _navigationColor(BuildContext context) =>
      Theme.of(context).navigationBarTheme.backgroundColor ??
      Theme.of(context).colorScheme.surfaceContainer;

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
  ) => [
    (label: 'Sessions completed', value: '${sessions.numberOfSessions}'),
    (label: 'Completed session time', value: _formatDuration(sessions.totalTimeSpent)),
    (label: 'Answers recorded', value: '${exercises.totalNumberAnswers}'),
    (label: 'Exercises completed', value: '${sessions.numberOfExercisesCompleted}'),
  ];

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
        _buildProgressRow(context, 'Exercise type', 'New', 'Started', 'Mastered', 'Total', isHeader: true),
        const SizedBox(height: 16),
        for (final type in types) ...[
          _buildProgressValues(
            context,
            type.label,
            widget.progressCounts.byType[type.key] ?? zero,
          ),
          const SizedBox(height: 18),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mastered means FSRS stability above 30 days.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF616161),
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
      if (!_showPercentages) return '$count';
      if (total == 0) return '—';
      return '${(count * 100 / total).toStringAsFixed(1)}%';
    }

    return _buildProgressRow(
      context,
      label,
      format(counts.notStarted),
      format(counts.started),
      format(counts.mastered),
      _showPercentages ? (total == 0 ? '—' : '100.0%') : '$total',
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
            color: const Color(0xFF616161),
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

  List<_BreakdownEntry> _sessionEntries() => [
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
  ];

  List<_BreakdownEntry> _gradeEntries() => [
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
  ];

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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF616161),
          ),
        ),
      ],
    );
  }
}
