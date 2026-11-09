import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:psitta/application/controllers/progress_controller.dart'
    show ContentImportAfterRestoreException, ProgressController;
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/controllers/settings_controller.dart';
import 'package:psitta/ui/screens/settings/about_screen.dart';
import 'package:psitta/ui/screens/settings/settings_controls.dart';
import 'package:psitta/ui/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController? settingsController;
  final SessionController? sessionController;
  final ProgressController? progressController;
  final ValueNotifier<AppThemeVariant>? themeVariant;
  final ValueChanged<bool>? onCharacterSessionsChanged;
  final VoidCallback? onSessionLimitsChanged;
  final VoidCallback? onProgressChanged;

  const SettingsScreen({
    this.settingsController,
    this.sessionController,
    this.progressController,
    this.themeVariant,
    this.onCharacterSessionsChanged,
    this.onSessionLimitsChanged,
    this.onProgressChanged,
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
  static const _reviewKey = 'sessions.reviews.max_count.v2';
  static const _legacyReviewKey = 'sessions.reviews.max_count';

  AppThemeVariant _theme = AppThemeVariant.light;
  bool _charactersEnabled = true;
  int _wordNewCount = 4;
  int _sentenceNewCount = 3;
  int _characterNewCount = 5;
  int _reviewCount = -1;
  bool _loading = true;
  bool _dataOperationInProgress = false;

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
        settings.get(_legacyReviewKey),
      ]);
      _theme = _themeFromString(values[0]);
      _charactersEnabled = values[1] != 'false';
      _wordNewCount = int.tryParse(values[2] ?? '') ?? 4;
      _sentenceNewCount = int.tryParse(values[3] ?? '') ?? 3;
      _characterNewCount = int.tryParse(values[4] ?? '') ?? 5;
      final storedReviewCount = values[5] ?? values[6];
      _reviewCount = int.tryParse(storedReviewCount ?? '') ?? -1;
      if (values[5] == null && values[6] != null) {
        if (_reviewCount == 9999) _reviewCount = -1;
        await _save(_reviewKey, '$_reviewCount');
      }
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openAbout(context),
                  label: const Text('About Psitta'),
                  icon: const Icon(Icons.info_outline),
                ),
              ),
              _buildAppearanceSection(context),
              const SizedBox(height: 16),
              _buildSessionSection(context),
              const SizedBox(height: 16),
              _buildDataSection(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return SettingsSection(
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
    return SettingsSection(
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
          _countControl(
            label: 'New word exercises per session',
            value: _wordNewCount,
            sliderMax: 25,
            onChanged: (value) => _saveSessionCount(_wordNewKey, value, 0),
          ),
          _countControl(
            label: 'New sentence exercises per session',
            value: _sentenceNewCount,
            sliderMax: 25,
            onChanged: (value) => _saveSessionCount(_sentenceNewKey, value, 1),
          ),
          _countControl(
            label: 'New Kana exercises per session',
            value: _characterNewCount,
            sliderMax: 25,
            onChanged: (value) => _saveSessionCount(_characterNewKey, value, 2),
          ),
          _countControl(
            label: 'Maximum reviews per session',
            value: _reviewCount,
            sliderMax: 100,
            minValue: -1,
            allowNegative: true,
            onChanged: (value) => _saveSessionCount(_reviewKey, value, 3),
          ),
        ],
      ),
    );
  }

  Widget _countControl({
    required String label,
    required int value,
    int minValue = 0,
    int maxValue = 999999,
    required int sliderMax,
    bool allowNegative = false,
    required ValueChanged<int> onChanged,
  }) {
    return NumericSliderSetting(
      label: label,
      value: value,
      minValue: minValue,
      maxValue: maxValue,
      sliderMax: sliderMax,
      enabled: !_loading,
      allowNegative: allowNegative,
      helperText: allowNegative
          ? 'Slider: 0–100. Type -1 for no limit, or enter 0–$maxValue.'
          : 'Slider: 0–$sliderMax. Type any value from 0 to $maxValue.',
      onChanged: onChanged,
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return SettingsSection(
      title: 'Data and progress',
      icon: Icons.storage_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_dataOperationInProgress) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          const Text(
            'Reset learning progress or save and restore a complete database backup.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _dataOperationInProgress || widget.progressController == null
                ? null
                : _confirmProgressReset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset progress'),
          ),
          OutlinedButton.icon(
            onPressed: _dataOperationInProgress || widget.progressController == null
                ? null
                : _showBackupOptions,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Save or restore database'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmProgressReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This deletes all exercise progress, answer history, session statistics, '
          'and your daily streak. Your exercise content and settings will remain. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset progress'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runDataOperation(() async {
      await widget.progressController?.resetAllProgress();
      widget.onProgressChanged?.call();
    }, successMessage: 'Learning progress reset.');
  }

  Future<void> _showBackupOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save a backup file'),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from a backup file'),
              onTap: () => Navigator.pop(context, 'restore'),
            ),
          ],
        ),
      ),
    );
    if (action == 'save') await _saveDatabaseBackup();
    if (action == 'restore') await _restoreDatabaseBackup();
  }

  Future<void> _saveDatabaseBackup() async {
    var saved = false;
    await _runDataOperation(
      () async {
        final bytes = await widget.progressController?.createDatabaseBackup();
        if (bytes == null) return;
        final result = await FilePicker.saveFile(
          dialogTitle: 'Save Psitta database backup',
          fileName: 'psitta-backup.db',
          bytes: bytes,
        );
        saved = result != null;
      },
      successMessage: 'Database backup saved.',
      showSuccess: () => saved,
    );
  }

  Future<void> _restoreDatabaseBackup() async {
    PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['db'],
      );
    } on Object catch (error) {
      _showDataOperationError(error);
      return;
    }
    if (!mounted) return;
    if (file == null) return;
    final selectedFile = file;
    Uint8List backupBytes;
    int backupVersion;
    setState(() => _dataOperationInProgress = true);
    try {
      backupBytes = await selectedFile.readAsBytes();
      backupVersion = await widget.progressController!.inspectDatabaseBackup(backupBytes);
    } on Object catch (error) {
      _showDataOperationError(error);
      return;
    } finally {
      if (mounted) setState(() => _dataOperationInProgress = false);
    }
    if (!mounted) return;
    final migrationRequired =
        backupVersion < widget.progressController!.currentSchemaVersion;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          migrationRequired
              ? 'Migrate and restore this backup?'
              : 'Restore this database?',
        ),
        content: Text(
          migrationRequired
              ? 'This backup uses database version $backupVersion. Psitta will '
                    'automatically migrate a temporary copy to version '
                    '${widget.progressController!.currentSchemaVersion} before '
                    'restoring it. This replaces all current content, settings, '
                    'progress, and statistics.'
              : 'Restoring replaces all current content, settings, progress, and '
                    'statistics with the selected backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(migrationRequired ? 'Migrate and restore' : 'Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runDataOperation(() async {
      try {
        await widget.progressController!.restoreDatabaseBackup(
          backupBytes,
          allowMigration: migrationRequired,
        );
      } on ContentImportAfterRestoreException {
        widget.onProgressChanged?.call();
        await _loadSettings();
        rethrow;
      }
      widget.onProgressChanged?.call();
      await _loadSettings();
    }, successMessage: 'Database restored.');
  }

  Future<void> _runDataOperation(
    Future<void> Function() operation, {
    required String successMessage,
    bool Function()? showSuccess,
  }) async {
    setState(() => _dataOperationInProgress = true);
    try {
      await operation();
      if (!mounted) return;
      if (showSuccess?.call() != false) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on Object catch (error) {
      _showDataOperationError(error);
    } finally {
      if (mounted) setState(() => _dataOperationInProgress = false);
    }
  }

  void _showDataOperationError(Object error) {
    if (!mounted) return;
    final message = error is ContentImportAfterRestoreException
        ? 'Database restored, but bundled content could not be reinstalled: $error'
        : 'Operation failed: $error';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
