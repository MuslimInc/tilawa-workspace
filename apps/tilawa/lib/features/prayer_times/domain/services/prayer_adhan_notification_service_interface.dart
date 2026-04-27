import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../entities/prayer_settings_entity.dart';
import '../entities/prayer_time_entity.dart';

/// Interface for the prayer adhan notification service.
///
/// Defines the contract for scheduling, cancelling and handling prayer-time
/// notifications. Domain code (use cases, BLoCs) depends only on this
/// interface — concrete implementations live in the application layer.
abstract interface class IPrayerAdhanNotificationService {
  /// Initialize the underlying notification plugin, register handlers and
  /// create notification channels. Safe to call multiple times.
  Future<void> initialize();

  /// Schedule prayer notifications across the configured day window using
  /// the supplied per-day [prayerTimesForDays] list. Implementations dedupe
  /// by a fingerprint of (settings + location + calculation method) plus the
  /// last-scheduled date; pass [forceReschedule] to bypass the dedup guard
  /// (e.g. when the user changes settings on the same day).
  Future<void> schedulePrayerNotifications({
    required PrayerSettingsEntity settings,
    required List<PrayerTimeEntity> prayerTimesForDays,
    bool forceReschedule = false,
  });

  /// Cancel every prayer notification scheduled by this service.
  Future<void> cancelAllPrayerNotifications();

  /// Handle a notification tap (foreground or background).
  Future<void> handleNotificationResponse(NotificationResponse response);

  /// Whether exact alarms can be scheduled on this device. Always `true` on
  /// Android < 12 and on non-Android platforms.
  Future<bool> canScheduleExactAlarms();

  /// Open the system's exact-alarm permission settings. No-op on platforms
  /// or OS versions where the permission does not exist.
  Future<void> requestExactAlarmPermission();

  /// Fire an immediate test notification for [prayer] using the given
  /// [playAdhan] flag. Intended only for debug / QA use.
  Future<void> fireTestNotification({
    required PrayerType prayer,
    required bool playAdhan,
  });
}
