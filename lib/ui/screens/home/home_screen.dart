import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/presentation/load_error_content.dart';
import 'package:psitta/ui/screens/home/home_content.dart';
import 'package:psitta/ui/screens/learning/learning_screen.dart';

/// Displays the available learning sessions and their current exercise counts.
class HomeScreen extends StatefulWidget {
  final SessionController sessionController;
  final ContentRenderer contentRenderer;

  const HomeScreen({
    required this.sessionController,
    required this.contentRenderer,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SessionOverview>> _sessionOverviews;
  bool _openingSession = false;

  @override
  void initState() {
    super.initState();
    _sessionOverviews = widget.sessionController.getSessionOverviews();
  }

  Future<void> _reload() {
    final loading = widget.sessionController.getSessionOverviews();
    setState(() {
      _sessionOverviews = loading;
    });
    return loading;
  }

  Future<void> _selectSession(SessionOverview overview) async {
    if (_openingSession) {
      return;
    }
    _openingSession = true;

    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => LearningScreen(
            sessionController: widget.sessionController,
            contentRenderer: widget.contentRenderer,
            sessionType: overview.sessionType,
            resumeSession: overview.hasActiveSession,
          ),
        ),
      );
    } finally {
      if (mounted) {
        _openingSession = false;
        await _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<SessionOverview>>(
        future: _sessionOverviews,
        builder: _buildContent,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<SessionOverview>> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return LoadErrorContent(
        message: 'The sessions could not be loaded.',
        error: snapshot.error!,
        onRetry: _reload,
      );
    }

    return HomeContent(
      overviews: snapshot.requireData,
      onRefresh: _reload,
      onSessionSelected: _selectSession,
    );
  }
}
