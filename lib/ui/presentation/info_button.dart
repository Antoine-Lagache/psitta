import 'package:flutter/material.dart';

/// Opens a short contextual explanation without taking space in the layout.
class InfoButton extends StatelessWidget {
  final String title;
  final String message;

  const InfoButton({required this.title, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More information: $title',
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.info_outline),
    );
  }
}
