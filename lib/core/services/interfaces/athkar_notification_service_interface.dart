import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Interface for the Athkar (remembrance) notification service
///
/// Defines the contract for scheduling and handling daily athkar notifications.
/// Implementations should handle:
/// - Morning athkar (أذكار الصباح) at 7:00 AM
/// - Evening athkar (أذكار المساء) at 5:00 PM
abstract interface class IAthkarNotificationService {
  /// Initialize the notification service
  Future<void> initialize();

  /// Schedule athkar notifications (both morning and evening)
  Future<void> scheduleAthkarNotifications();

  /// Cancel all athkar notifications
  Future<void> cancelAllAthkarNotifications();

  /// Handle notification tap (foreground/background)
  Future<void> handleNotificationResponse(NotificationResponse response);

  /// Check if the app was launched from an athkar notification
  /// Returns the notification response if so, null otherwise.
  Future<NotificationResponse?> checkLaunchNotification();

  /// Clear the stored launch notification data
  /// Call this after successfully handling a notification navigation
  Future<void> clearLaunchNotificationData();

  /// Schedule a test notification (for testing purposes)
  Future<void> scheduleTestNotification({int minutesFromNow = 1});

  /// Schedule a debug athkar notification with custom delay
  Future<void> scheduleDebugAthkarNotification({
    required bool isMorning,
    Duration delay = const Duration(minutes: 1),
  });
}
