import 'package:shared_preferences/shared_preferences.dart';

/// Persists a background `session_revoked` FCM until the app foregrounds.
///
/// Background isolates cannot use get_it; this store uses [SharedPreferences]
/// directly with the same key as [TokenSyncCacheImpl].
abstract final class PendingSessionRevokeStore {
  static const String key = 'pending_session_revoke';

  static Future<void> mark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Returns true once, then clears the flag.
  static Future<bool> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(key) ?? false;
    if (pending) {
      await prefs.remove(key);
    }
    return pending;
  }
}
