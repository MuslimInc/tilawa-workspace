import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/shared_preferences_migration.dart';

/// Persists a background `session_revoked` FCM until the app foregrounds.
///
/// Background isolates cannot use get_it; this store uses [SharedPreferencesAsync]
/// directly with the same key as [TokenSyncCacheImpl].
abstract final class PendingSessionRevokeStore {
  static const String key = 'pending_session_revoke';

  static SharedPreferencesAsync Function()? _prefsFactoryForTesting;

  static SharedPreferencesAsync _prefs() =>
      _prefsFactoryForTesting?.call() ??
      SharedPreferencesAsync(options: tilawaSharedPreferencesOptions);

  @visibleForTesting
  static void setPrefsFactoryForTesting(
    SharedPreferencesAsync Function()? factory,
  ) {
    _prefsFactoryForTesting = factory;
  }

  static Future<void> mark() async {
    await _prefs().setBool(key, true);
  }

  static Future<void> clear() async {
    await _prefs().remove(key);
  }

  /// Returns true once, then clears the flag.
  static Future<bool> consume() async {
    final pending = await _prefs().getBool(key) ?? false;
    if (pending) {
      await _prefs().remove(key);
    }
    return pending;
  }
}
