import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/statistic_controller.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/ui/presentation/load_error_content.dart';
import 'package:psitta/ui/screens/statistics/statistics_content.dart';

typedef _StatisticsData = ({
  ExerciseStatistics exercises,
  SessionStatistics sessions,
  ExerciseStatistics todayExercises,
  SessionStatistics todaySessions,
});

/// Loads and displays today's and all-time statistics.
class StatisticsScreen extends StatefulWidget {
  final StatisticController statisticController;
  final ValueListenable<int> refreshSignal;

  const StatisticsScreen({
    required this.statisticController,
    required this.refreshSignal,
    super.key,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<_StatisticsData> _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = _loadStatistics();
    widget.refreshSignal.addListener(_refreshOnSignal);
  }

  @override
  void didUpdateWidget(StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal.removeListener(_refreshOnSignal);
      widget.refreshSignal.addListener(_refreshOnSignal);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal.removeListener(_refreshOnSignal);
    super.dispose();
  }

  void _refreshOnSignal() {
    _reload();
  }

  Future<_StatisticsData> _loadStatistics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // These are independent read transactions. A strict shared snapshot would
    // require one repository operation backed by a single read transaction.
    final (sessions, exercises, todaySessions, todayExercises) = await (
      widget.statisticController.getSessionStatistics(),
      widget.statisticController.getExerciseStatistics(),
      widget.statisticController.getSessionStatistics(
        startDate: todayStart.toUtc(),
        endDate: tomorrowStart.toUtc(),
      ),
      widget.statisticController.getExerciseStatistics(
        startDate: todayStart.toUtc(),
        endDate: tomorrowStart.toUtc(),
      ),
    ).wait;

    return (
      sessions: sessions,
      exercises: exercises,
      todaySessions: todaySessions,
      todayExercises: todayExercises,
    );
  }

  Future<void> _reload() {
    final loading = _loadStatistics();
    setState(() {
      _statistics = loading;
    });
    return loading;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_StatisticsData>(future: _statistics, builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<_StatisticsData> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return LoadErrorContent(
        message: 'The statistics could not be loaded.',
        error: snapshot.error!,
        onRetry: _reload,
      );
    }

    final data = snapshot.requireData;
    return StatisticsContent(
      sessionStatistics: data.sessions,
      exerciseStatistics: data.exercises,
      todaySessionStatistics: data.todaySessions,
      todayExerciseStatistics: data.todayExercises,
      onRefresh: _reload,
    );
  }
}
