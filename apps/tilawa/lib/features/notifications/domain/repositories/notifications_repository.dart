abstract class NotificationsRepository {
  /// Request permission to show notifications
  Future<void> requestPermission();

  /// Get the FCM token for this device
  Future<String?> getToken();

  /// Initialize listeners for foreground and background messages
  Future<void> initializeListeners();
}
