import '../../models/settings_model.dart';

abstract class ISettingsRepository {
  Future<SettingsModel> getSettings();
  Future<bool> saveSettings(SettingsModel settings);
}
