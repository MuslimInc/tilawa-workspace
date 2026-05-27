abstract interface class StartupNotificationRepository {
  /// Consumes and returns the pending cold-start notification data.
  ///
  /// Returns null when no notification is pending.
  /// Returns an empty map when a notification is pending but has no parseable payload.
  Map<String, dynamic>? consumePendingNotification();
}
