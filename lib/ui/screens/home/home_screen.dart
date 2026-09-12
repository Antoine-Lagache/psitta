import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/domain/sessions/session_type.dart';

typedef _ActiveSessionCounts = ({int word, int sentence});

/// Displays the available session types and their unfinished session counts.
class HomeScreen extends StatefulWidget {
  final SessionController sessionController;

  const HomeScreen({required this.sessionController, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_ActiveSessionCounts> _activeSessionCounts;

  @override
  void initState() {
    super.initState();
    _activeSessionCounts = _loadActiveSessionCounts();
  }

  Future<_ActiveSessionCounts> _loadActiveSessionCounts() async {
    final counts = await Future.wait<int>([
      widget.sessionController.numberActiveSession(SessionType.wordSession),
      widget.sessionController.numberActiveSession(SessionType.sentenceSession),
    ]);

    return (word: counts[0], sentence: counts[1]);
  }

  void _retryLoading() {
    setState(() {
      _activeSessionCounts = _loadActiveSessionCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Psitta')),
      body: FutureBuilder<_ActiveSessionCounts>(
        future: _activeSessionCounts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HomeLoadError(
              error: snapshot.error!,
              onRetry: _retryLoading,
            );
          }

          final counts = snapshot.requireData;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SessionCard(
                title: 'Word session',
                activeSessionCount: counts.word,
              ),
              const SizedBox(height: 16),
              _SessionCard(
                title: 'Sentence session',
                activeSessionCount: counts.sentence,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final int activeSessionCount;

  const _SessionCard({required this.title, required this.activeSessionCount});

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = activeSessionCount > 0;
    final sessionLabel = activeSessionCount == 1 ? 'session' : 'sessions';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              hasActiveSession
                  ? '$activeSessionCount unfinished $sessionLabel'
                  : 'No unfinished session',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: null,
              child: Text(hasActiveSession ? 'Resume' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _HomeLoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The sessions could not be loaded.'),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
