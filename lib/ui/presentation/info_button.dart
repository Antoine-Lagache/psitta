import 'package:flutter/material.dart';

/// Shows an explanatory dialog from a labeled action.
class InfoButton extends StatelessWidget {
  final String label;
  final String title;
  final String message;

  const InfoButton({
    required this.label,
    required this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.info_outline),
      label: Text(label),
    );
  }
}
