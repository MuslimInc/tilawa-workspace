import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/token_sync_cache.dart';

@LazySingleton(as: TokenSyncCache)
class TokenSyncCacheImpl implements TokenSyncCache {
  TokenSyncCacheImpl(this._prefs);

  static const String _lastSyncedTokenKey = 'last_synced_fcm_token';
  static const String _lastSyncedUserIdKey = 'last_synced_fcm_user_id';
  static const String _sessionEpochKey = 'session_epoch';
  static const String _activeDeviceIdKey = 'active_device_id';

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> getLastSyncedToken() => _prefs.getString(_lastSyncedTokenKey);

  @override
  Future<String?> getLastSyncedUserId() =>
      _prefs.getString(_lastSyncedUserIdKey);

  @override
  Future<void> saveSync(String token, String userId) async {
    await _prefs.setString(_lastSyncedTokenKey, token);
    await _prefs.setString(_lastSyncedUserIdKey, userId);
  }

  @override
  Future<void> clearSync() async {
    await _prefs.remove(_lastSyncedTokenKey);
    await _prefs.remove(_lastSyncedUserIdKey);
  }

  @override
  Future<int?> getSessionEpoch() async {
    final value = await _prefs.getInt(_sessionEpochKey);
    return value;
  }

  @override
  Future<void> saveSessionEpoch(int epoch) async {
    await _prefs.setInt(_sessionEpochKey, epoch);
  }

  @override
  Future<String?> getActiveDeviceId() => _prefs.getString(_activeDeviceIdKey);

  @override
  Future<void> saveActiveDeviceId(String deviceId) async {
    await _prefs.setString(_activeDeviceIdKey, deviceId);
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_sessionEpochKey);
    await _prefs.remove(_activeDeviceIdKey);
    await clearSync();
  }
}
