import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

final Uri _websiteUri = Uri.parse('https://psitta.net');
final Uri _sourceCodeUri = Uri.parse('https://github.com/Antoine-Lagache/psitta');

/// Presents the application information and its external links.
class AboutScreen extends StatelessWidget {
  final ExternalLinkLauncher? linkLauncher;

  const AboutScreen({this.linkLauncher, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Psitta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.school_outlined, size: 56),
        const SizedBox(height: 20),
        Text(
          'Psitta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'A language-learning application built around spaced repetition.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text('Created by Antoine Lagache.', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        _buildLinkButton(
          context: context,
          icon: Icons.language,
          label: 'Psitta website',
          uri: _websiteUri,
        ),
        const SizedBox(height: 12),
        _buildLinkButton(
          context: context,
          icon: Icons.code,
          label: 'Source code',
          uri: _sourceCodeUri,
        ),
      ],
    );
  }

  Widget _buildLinkButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Uri uri,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _openLink(context, uri),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      final launcher = linkLauncher ?? _launchExternalLink;
      final launched = await launcher(uri);
      if (!launched && context.mounted) {
        await _showLinkError(context, uri);
      }
    } on Object catch (error) {
      if (context.mounted) {
        await _showLinkError(context, uri, error);
      }
    }
  }

  Future<void> _showLinkError(BuildContext context, Uri uri, [Object? error]) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to open link'),
        content: SelectableText(_linkErrorMessage(uri, error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _linkErrorMessage(Uri uri, Object? error) {
    final message = 'The following link could not be opened:\n$uri';
    return error == null ? message : '$message\n\n$error';
  }
}

Future<bool> _launchExternalLink(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
