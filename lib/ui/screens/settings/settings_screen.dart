import 'package:flutter/material.dart';

/// Placeholder for the future settings interface.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: _buildPlaceholder(context)),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.settings_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Settings will be available in a future update.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
