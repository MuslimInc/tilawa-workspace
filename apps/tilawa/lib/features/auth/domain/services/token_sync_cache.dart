/// Abstraction for caching device token sync state and session epoch.
///
/// Tracks which FCM token was last synced for which user, the active device id,
/// and the server session epoch for single-active-device enforcement.
abstract class TokenSyncCache {
  Future<String?> getLastSyncedToken();
  Future<String?> getLastSyncedUserId();
  Future<void> saveSync(String token, String userId);
  Future<void> clearSync();

  Future<int?> getSessionEpoch();
  Future<void> saveSessionEpoch(int epoch);
  Future<String?> getActiveDeviceId();
  Future<void> saveActiveDeviceId(String deviceId);
  Future<void> clearSession();
}
