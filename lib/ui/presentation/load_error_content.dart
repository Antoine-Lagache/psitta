import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays a recoverable loading error with an optional debug detail.
class LoadErrorContent extends StatelessWidget {
  final String message;
  final Object error;
  final VoidCallback onRetry;

  const LoadErrorContent({
    required this.message,
    required this.error,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildChildren(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    return [
      const Icon(Icons.error_outline, size: 40),
      const SizedBox(height: 16),
      SelectableText(
        message,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      if (kDebugMode) ...[
        const SizedBox(height: 8),
        SelectableText(error.toString(), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 20),
      FilledButton(onPressed: onRetry, child: const Text('Retry')),
    ];
  }
}
