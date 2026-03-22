/// Abstraction for caching device token sync state.
///
/// Tracks which FCM token was last synced for which user, so we can detect
/// token rotation and clean up stale registrations.
abstract class TokenSyncCache {
  Future<String?> getLastSyncedToken();
  Future<String?> getLastSyncedUserId();
  Future<void> saveSync(String token, String userId);
  Future<void> clearSync();
}
