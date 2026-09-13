import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays startup progress or an initialization failure with a retry action.
class StartupScreen extends StatelessWidget {
  final Object? _error;
  final VoidCallback? _onRetry;

  const StartupScreen.loading({super.key}) : _error = null, _onRetry = null;

  const StartupScreen.failure({
    required Object error,
    required VoidCallback onRetry,
    super.key,
  }) : _error = error,
       _onRetry = onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Psitta could not be initialized.'),
                      if (kDebugMode) ...[
                        const SizedBox(height: 8),
                        Text(_error.toString(), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
