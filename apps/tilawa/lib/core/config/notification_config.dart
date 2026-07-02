class NotificationConfig {
  /// Whether to enable local notifications for the application
  /// This controls both the local notification service and Flutter Downloader notifications
  static bool enableLocalNotifications = true;

  /// Android status-bar / shade small icon (`res/drawable`, no extension).
  ///
  /// Must be a white alpha mask on a transparent background — not the launcher
  /// monochrome asset (which includes an opaque backdrop and renders tiny).
  static const String androidSmallIcon = 'ic_notification';
}
