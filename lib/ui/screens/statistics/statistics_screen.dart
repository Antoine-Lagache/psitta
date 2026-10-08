import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/statistic_controller.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/ui/presentation/load_error_content.dart';
import 'package:psitta/ui/screens/statistics/statistics_content.dart';

typedef _StatisticsData = ({ExerciseStatistics exercises, SessionStatistics sessions});

/// Loads and displays the all-time statistics available in the MVP.
class StatisticsScreen extends StatefulWidget {
  final StatisticController statisticController;

  const StatisticsScreen({required this.statisticController, super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<_StatisticsData> _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = _loadStatistics();
  }

  Future<_StatisticsData> _loadStatistics() async {
    // These are independent read transactions. A strict shared snapshot would
    // require one repository operation backed by a single read transaction.
    final (sessions, exercises) = await (
      widget.statisticController.getSessionStatistics(),
      widget.statisticController.getExerciseStatistics(),
    ).wait;

    return (sessions: sessions, exercises: exercises);
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
      onRefresh: _reload,
    );
  }
}
