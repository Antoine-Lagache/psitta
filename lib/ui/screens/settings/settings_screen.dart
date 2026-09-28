import 'package:flutter/material.dart';
import 'package:psitta/ui/screens/settings/about_screen.dart';

/// Placeholder for the future settings interface.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.settings_outlined, size: 48),
        const SizedBox(height: 16),
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Settings will be available in a future update.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => _openAbout(context),
          icon: const Icon(Icons.info_outline),
          label: const Text('About Psitta'),
        ),
      ],
    );
  }

  void _openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
    );
  }
}
