import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/token_sync_cache.dart';

@LazySingleton(as: TokenSyncCache)
class TokenSyncCacheImpl implements TokenSyncCache {
  TokenSyncCacheImpl(this._prefs);

  static const String _lastSyncedTokenKey = 'last_synced_fcm_token';
  static const String _lastSyncedUserIdKey = 'last_synced_fcm_user_id';

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> getLastSyncedToken() =>
      _prefs.getString(_lastSyncedTokenKey);

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
}
