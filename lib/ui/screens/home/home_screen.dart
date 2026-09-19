import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/ui/screens/home/home_content.dart';

/// Displays the available learning sessions and their current exercise counts.
class HomeScreen extends StatefulWidget {
  final SessionController sessionController;

  const HomeScreen({required this.sessionController, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SessionOverview>> _sessionOverviews;

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

  void _selectSession(SessionOverview _) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The learning screen will be available soon.'),
      ),
    );
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
      return _buildLoadError(snapshot.error!);
    }

    return HomeContent(
      overviews: snapshot.requireData,
      onRefresh: _reload,
      onSessionSelected: _selectSession,
    );
  }

  Widget _buildLoadError(Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 16),
            Text(
              'The sessions could not be loaded.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
