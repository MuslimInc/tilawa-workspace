import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback type for notification handlers
typedef NotificationHandler = Future<void> Function(NotificationResponse);

/// Interface for the central notification dispatcher
///
/// Handles routing of notification responses to the appropriate service
/// based on notification ID or payload content.
abstract interface class INotificationDispatcher {
  /// Initialize the dispatcher and notification plugin
  Future<void> initialize({bool createHighImportanceChannel = true});

  /// Register a handler for specific notification IDs
  void registerHandler({
    required String serviceId,
    required Set<int> notificationIds,
    required NotificationHandler handler,
  });

  /// Register a fallback handler for payloads that match a pattern
  void registerPayloadHandler({
    required String serviceId,
    required bool Function(String? payload) matcher,
    required NotificationHandler handler,
  });

  /// Unregister a handler by service ID
  void unregisterHandler(String serviceId);

  /// Get notification launch details (for cold start handling)
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails();

  /// Process any pending launch notification through registered handlers
  ///
  /// This should be called AFTER all handlers are registered to handle
  /// cold start notification taps. Returns true if a notification was
  /// processed, false otherwise.
  Future<bool> processLaunchNotification();

  /// Get the notifications plugin for scheduling notifications
  FlutterLocalNotificationsPlugin get notificationsPlugin;
}
