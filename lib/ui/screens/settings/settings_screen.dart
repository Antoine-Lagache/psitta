import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/controllers/settings_controller.dart';
import 'package:psitta/ui/screens/settings/about_screen.dart';
import 'package:psitta/ui/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController? settingsController;
  final SessionController? sessionController;
  final ValueNotifier<AppThemeVariant>? themeVariant;
  final ValueChanged<bool>? onCharacterSessionsChanged;
  final VoidCallback? onSessionLimitsChanged;

  const SettingsScreen({
    this.settingsController,
    this.sessionController,
    this.themeVariant,
    this.onCharacterSessionsChanged,
    this.onSessionLimitsChanged,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _themeKey = 'appearance.theme';
  static const _charactersKey = 'sessions.characters.enabled';
  static const _wordNewKey = 'sessions.words.new_count';
  static const _sentenceNewKey = 'sessions.sentences.new_count';
  static const _characterNewKey = 'sessions.characters.new_count';
  static const _reviewKey = 'sessions.reviews.max_count';

  AppThemeVariant _theme = AppThemeVariant.light;
  bool _charactersEnabled = true;
  int _wordNewCount = 4;
  int _sentenceNewCount = 3;
  int _characterNewCount = 5;
  int _reviewCount = 9999;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = widget.settingsController;
    if (settings != null) {
      final values = await Future.wait([
        settings.get(_themeKey),
        settings.get(_charactersKey),
        settings.get(_wordNewKey),
        settings.get(_sentenceNewKey),
        settings.get(_characterNewKey),
        settings.get(_reviewKey),
      ]);
      _theme = _themeFromString(values[0]);
      _charactersEnabled = values[1] != 'false';
      _wordNewCount = int.tryParse(values[2] ?? '') ?? _wordNewCount;
      _sentenceNewCount = int.tryParse(values[3] ?? '') ?? _sentenceNewCount;
      _characterNewCount = int.tryParse(values[4] ?? '') ?? _characterNewCount;
      _reviewCount = int.tryParse(values[5] ?? '') ?? _reviewCount;
      widget.themeVariant?.value = _theme;
      _applySessionLimits();
      widget.onCharacterSessionsChanged?.call(_charactersEnabled);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              _buildAppearanceSection(context),
              const SizedBox(height: 16),
              _buildSessionSection(context),
              const SizedBox(height: 16),
              _buildDataSection(context),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openAbout(context),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('About Psitta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return _SettingsSection(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      child: DropdownButtonFormField<AppThemeVariant>(
        key: ValueKey(_theme),
        initialValue: _theme,
        decoration: const InputDecoration(labelText: 'Color theme'),
        items: const [
          DropdownMenuItem(value: AppThemeVariant.light, child: Text('Light')),
          DropdownMenuItem(value: AppThemeVariant.dark, child: Text('Dark')),
          DropdownMenuItem(value: AppThemeVariant.psitta, child: Text('Psitta')),
        ],
        onChanged: _loading
            ? null
            : (value) {
                if (value != null) _saveTheme(value);
              },
      ),
    );
  }

  Widget _buildSessionSection(BuildContext context) {
    return _SettingsSection(
      title: 'Sessions',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kana sessions'),
            subtitle: const Text('Show or hide character recognition sessions.'),
            value: _charactersEnabled,
            onChanged: _loading ? null : _saveCharacterSessionsEnabled,
          ),
          const Divider(),
          _countDropdown(
            label: 'New word exercises per session',
            value: _wordNewCount,
            onChanged: (value) => _saveSessionCount(_wordNewKey, value, 0),
          ),
          _countDropdown(
            label: 'New sentence exercises per session',
            value: _sentenceNewCount,
            onChanged: (value) => _saveSessionCount(_sentenceNewKey, value, 1),
          ),
          _countDropdown(
            label: 'New Kana exercises per session',
            value: _characterNewCount,
            onChanged: (value) => _saveSessionCount(_characterNewKey, value, 2),
          ),
          _countDropdown(
            label: 'Maximum reviews per session',
            value: _reviewCount,
            onChanged: (value) => _saveSessionCount(_reviewKey, value, 3),
            values: const [10, 20, 30, 50, 100, 9999],
            labels: const {
              10: '10',
              20: '20',
              30: '30',
              50: '50',
              100: '100',
              9999: 'No limit',
            },
          ),
        ],
      ),
    );
  }

  Widget _countDropdown({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    List<int> values = const [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20],
    Map<int, String> labels = const {},
  }) {
    final options = values.contains(value) ? values : ([...values, value]..sort());
    return DropdownButtonFormField<int>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(labels[option] ?? '$option')),
      ],
      onChanged: _loading
          ? null
          : (next) {
              if (next != null) onChanged(next);
            },
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return _SettingsSection(
      title: 'Data and progress',
      icon: Icons.storage_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Reset progress and database backup tools will be available here.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset progress'),
          ),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Backup or restore database'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTheme(AppThemeVariant value) async {
    setState(() => _theme = value);
    widget.themeVariant?.value = value;
    await _save(_themeKey, _themeToString(value));
  }

  Future<void> _saveCharacterSessionsEnabled(bool value) async {
    setState(() => _charactersEnabled = value);
    widget.onCharacterSessionsChanged?.call(value);
    await _save(_charactersKey, '$value');
  }

  Future<void> _saveSessionCount(String key, int value, int type) async {
    setState(() {
      switch (type) {
        case 0:
          _wordNewCount = value;
          break;
        case 1:
          _sentenceNewCount = value;
          break;
        case 2:
          _characterNewCount = value;
          break;
        case 3:
          _reviewCount = value;
          break;
      }
    });
    _applySessionLimits();
    widget.onSessionLimitsChanged?.call();
    await _save(key, '$value');
  }

  void _applySessionLimits() {
    final controller = widget.sessionController;
    if (controller == null) return;
    if (controller.hasActiveSession) return;
    controller.updateSessionLimits(
      newWordCount: _wordNewCount,
      newSentenceCount: _sentenceNewCount,
      newCharacterCount: _characterNewCount,
      reviewCount: _reviewCount,
    );
  }

  Future<void> _save(String key, String value) async {
    try {
      await widget.settingsController?.set(key, value);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Setting could not be saved: $error')));
    }
  }

  void _openAbout(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
  }

  static AppThemeVariant _themeFromString(String? value) => switch (value) {
    'dark' => AppThemeVariant.dark,
    'psitta' => AppThemeVariant.psitta,
    _ => AppThemeVariant.light,
  };

  static String _themeToString(AppThemeVariant value) => switch (value) {
    AppThemeVariant.light => 'light',
    AppThemeVariant.dark => 'dark',
    AppThemeVariant.psitta => 'psitta',
  };
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
