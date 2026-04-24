import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';

class QuranAssetsPrefetchPolicyService {
  QuranAssetsPrefetchPolicyService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? getIt<SharedPreferencesAsync>();

  static const String _wifiOnlyKey = 'quran_assets_prefetch_wifi_only';

  final SharedPreferencesAsync _preferences;

  Future<bool> isWifiOnlyEnabled() async {
    return await _preferences.getBool(_wifiOnlyKey) ?? true;
  }

  Future<void> setWifiOnlyEnabled(bool enabled) {
    return _preferences.setBool(_wifiOnlyKey, enabled);
  }
}
