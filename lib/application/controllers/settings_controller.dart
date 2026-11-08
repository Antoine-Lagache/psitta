import 'package:psitta/infrastructure/persistence/dao/app_setting_dao.dart';

/// Generic key/value access for application settings.
///
/// Setting names, defaults and validation belong to the UI/features using
/// them; this controller deliberately does not define a catalogue of settings.
class SettingsController {
  final AppSettingDao _settings;

  SettingsController(this._settings);

  Future<String?> get(String key) => _settings.get(key);

  Future<void> set(String key, String value) => _settings.set(key, value);
}
