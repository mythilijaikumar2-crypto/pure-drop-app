import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../models/settings_model.dart';
import '../interfaces/i_settings_repository.dart';

class HiveSettingsRepository implements ISettingsRepository {
  @override
  Future<SettingsModel> getSettings() async {
    try {
      final box = HiveService.getBox(AppConstants.settingsBoxName);
      final raw = box.get('app_settings');
      if (raw == null) {
        final defaultSettings = SettingsModel();
        await saveSettings(defaultSettings);
        return defaultSettings;
      }
      return SettingsModel.fromJson(jsonDecode(raw as String));
    } catch (_) {
      return SettingsModel();
    }
  }

  @override
  Future<bool> saveSettings(SettingsModel settings) async {
    try {
      final box = HiveService.getBox(AppConstants.settingsBoxName);
      await box.put('app_settings', jsonEncode(settings.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }
}
