import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class QuranAssetsPrefetchPolicyService {
  QuranAssetsPrefetchPolicyService(this._preferences);

  static const String _wifiOnlyKey = 'quran_assets_prefetch_wifi_only';

  final SharedPreferencesAsync _preferences;

  @factoryMethod
  QuranAssetsPrefetchPolicyService.fromPreferences(
    SharedPreferencesAsync preferences,
  ) : _preferences = preferences;

  Future<bool> isWifiOnlyEnabled() async {
    return await _preferences.getBool(_wifiOnlyKey) ?? true;
  }

  Future<void> setWifiOnlyEnabled(bool enabled) {
    return _preferences.setBool(_wifiOnlyKey, enabled);
  }
}
