import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quran_sessions_platform_config.dart';

class SharedPreferencesPlatformConfigDataSource {
  SharedPreferencesPlatformConfigDataSource(this._preferences);

  static const cacheKey = 'quran_sessions_platform_config_global_v1';

  final SharedPreferencesAsync _preferences;

  Future<QuranSessionsPlatformConfig?> load() async {
    final raw = await _preferences.getString(cacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return QuranSessionsPlatformConfig.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  Future<void> save(QuranSessionsPlatformConfig config) {
    return _preferences.setString(cacheKey, jsonEncode(config.toJson()));
  }

  Future<void> clear() {
    return _preferences.remove(cacheKey);
  }
}
