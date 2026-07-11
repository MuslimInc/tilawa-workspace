import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/entities.dart';

abstract class PrayerSettingsDataSource {
  Future<PrayerSettingsEntity> loadSettings();
  Future<void> saveSettings(PrayerSettingsEntity settings);
  Future<void> clearSettings();
}

@LazySingleton(as: PrayerSettingsDataSource)
class PrayerSettingsDataSourceImpl implements PrayerSettingsDataSource {
  PrayerSettingsDataSourceImpl(this._prefs);

  static const String _settingsKey = 'prayer_settings';

  final SharedPreferencesAsync _prefs;

  @override
  Future<PrayerSettingsEntity> loadSettings() async {
    final String? settingsJson = await _prefs.getString(_settingsKey);

    if (settingsJson == null) {
      return const PrayerSettingsEntity();
    }

    try {
      final json = jsonDecode(settingsJson) as Map<String, dynamic>;
      return PrayerSettingsEntity.fromJson(json);
    } catch (e) {
      return const PrayerSettingsEntity();
    }
  }

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {
    final String settingsJson = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, settingsJson);
  }

  @override
  Future<void> clearSettings() async {
    await _prefs.remove(_settingsKey);
  }
}
