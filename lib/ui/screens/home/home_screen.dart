import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/presentation/load_error_content.dart';
import 'package:psitta/ui/screens/home/home_content.dart';
import 'package:psitta/ui/screens/learning/learning_screen.dart';

/// Displays the available learning sessions and their current exercise counts.
class HomeScreen extends StatefulWidget {
  final SessionController sessionController;
  final ContentRenderer contentRenderer;
  final Future<bool>? backgroundContentImport;

  const HomeScreen({
    required this.sessionController,
    required this.contentRenderer,
    this.backgroundContentImport,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SessionOverview>> _sessionOverviews;
  bool _openingSession = false;
  bool _loadingCharacters = false;
  bool _characterLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _sessionOverviews = widget.sessionController.getSessionOverviews();
    _loadingCharacters = widget.backgroundContentImport != null;
    if (_loadingCharacters) unawaited(_loadCharacters());
  }

  Future<void> _loadCharacters() async {
    try {
      await widget.backgroundContentImport;
      if (!mounted) return;
      // Keep the character action disabled until the fresh counts are ready.
      await _reload();
      if (mounted) setState(() => _loadingCharacters = false);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCharacters = false;
        _characterLoadFailed = true;
      });
    }
  }

  Future<void> _reload() {
    final loading = widget.sessionController.getSessionOverviews();
    setState(() {
      _sessionOverviews = loading;
    });
    return loading;
  }

  Future<void> _selectSession(SessionOverview overview) async {
    if (_openingSession ||
        (overview.sessionType == SessionType.characterSession &&
            (_loadingCharacters || _characterLoadFailed))) {
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
      loadingCharacters: _loadingCharacters,
      characterLoadFailed: _characterLoadFailed,
      onRefresh: _reload,
      onSessionSelected: _selectSession,
    );
  }
}
