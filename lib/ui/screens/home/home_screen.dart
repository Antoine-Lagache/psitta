import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/ui/screens/home/session_overview_card.dart';

/// Displays the available learning sessions and their current exercise counts.
class HomeScreen extends StatefulWidget {
  final SessionController sessionController;

  /// Delegates navigation without making the home screen own session routes.
  /// It remains optional until the learning screen is implemented.
  final ValueChanged<SessionOverview>? onSessionSelected;

  const HomeScreen({
    required this.sessionController,
    this.onSessionSelected,
    super.key,
  });

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

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sessionController != widget.sessionController) {
      _sessionOverviews = widget.sessionController.getSessionOverviews();
    }
  }

  void _retryLoading() {
    setState(() {
      _sessionOverviews = widget.sessionController.getSessionOverviews();
    });
  }

  void _selectSession(SessionOverview overview) {
    final onSessionSelected = widget.onSessionSelected;

    if (onSessionSelected != null) {
      onSessionSelected(overview);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The learning screen will be available soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Psitta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<SessionOverview>>(
          future: _sessionOverviews,
          builder: _buildContent,
        ),
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

    return _buildSessionList(snapshot.requireData);
  }

  Widget _buildSessionList(List<SessionOverview> overviews) {
    return RefreshIndicator(
      onRefresh: () async {
        _retryLoading();
        await _sessionOverviews;
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Choose a session',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review what is due or start learning something new.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 28),
              for (var index = 0; index < overviews.length; index++) ...[
                SessionOverviewCard(
                  overview: overviews[index],
                  onPressed: () => _selectSession(overviews[index]),
                ),
                if (index < overviews.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
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
            FilledButton(onPressed: _retryLoading, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
