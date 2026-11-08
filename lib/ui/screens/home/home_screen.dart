import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psitta/application/startup/content_release_state.dart';
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
  final ContentReleaseState contentReleaseState;
  final bool characterSessionsEnabled;
  final ValueListenable<int>? refreshSignal;

  const HomeScreen({
    required this.sessionController,
    required this.contentRenderer,
    required this.contentReleaseState,
    this.characterSessionsEnabled = true,
    this.refreshSignal,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SessionOverview>> _sessionOverviews;
  bool _openingSession = false;
  ContentReleaseStatus? _lastContentStatus;

  @override
  void initState() {
    super.initState();
    _sessionOverviews = widget.sessionController.getSessionOverviews();
    _lastContentStatus = widget.contentReleaseState.status;
    widget.contentReleaseState.addListener(_onContentReleaseChanged);
    widget.refreshSignal?.addListener(_onExternalRefresh);
  }

  void _onExternalRefresh() {
    if (mounted) unawaited(_reload());
  }

  void _onContentReleaseChanged() {
    final status = widget.contentReleaseState.status;
    if (status == _lastContentStatus) return;
    _lastContentStatus = status;
    if (status == ContentReleaseStatus.ready) {
      unawaited(_reload());
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.contentReleaseState.removeListener(_onContentReleaseChanged);
    widget.refreshSignal?.removeListener(_onExternalRefresh);
    super.dispose();
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
            widget.contentReleaseState.status != ContentReleaseStatus.ready)) {
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

  Future<void> _abandonSession(SessionOverview overview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon this session?'),
        content: const Text(
          'The saved session and its session statistics will be removed. '
          'Answers already submitted keep their exercise progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep session'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Abandon session'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.sessionController.abandonSession(overview.sessionType);
      if (mounted) await _reload();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'home screen',
          context: ErrorDescription('while abandoning a paused session'),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The session could not be abandoned.')),
        );
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
      overviews: snapshot.requireData
          .where(
            (overview) =>
                widget.characterSessionsEnabled ||
                overview.hasActiveSession ||
                overview.sessionType != SessionType.characterSession,
          )
          .toList(),
      loadingCharacters: widget.contentReleaseState.isLoading,
      characterLoadFailed: widget.contentReleaseState.hasFailed,
      onRefresh: _reload,
      onSessionSelected: _selectSession,
      onSessionAbandon: (overview) => _abandonSession(overview),
    );
  }
}
