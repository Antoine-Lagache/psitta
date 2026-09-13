import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays startup progress or an initialization failure with a retry action.
class StartupScreen extends StatelessWidget {
  final Widget _content;

  const StartupScreen._({required Widget content, super.key}) : _content = content;

  const StartupScreen.loading({super.key}) : _content = const CircularProgressIndicator();

  factory StartupScreen.failure({
    required Object error,
    required VoidCallback onRetry,
    Key? key,
  }) {
    return StartupScreen._(
      key: key,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Psitta could not be initialized.'),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _content,
          ),
        ),
      ),
    );
  }
}
