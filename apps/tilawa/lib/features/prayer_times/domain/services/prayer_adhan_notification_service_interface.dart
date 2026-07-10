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

  /// DEBUG ONLY: Schedules a prayer notification and a native Adhan alarm
  /// exactly 10 seconds from now. Intended for manual QA of the app-kill
  /// scenario.
  Future<AdhanDebugScheduleResult> debugScheduleTestAdhan();
}

/// Result of scheduling the debug Adhan test.
///
/// The manual QA tile uses this to distinguish native playback from the
/// Flutter-local-notification fallback instead of inferring success from
/// permissions alone.
final class AdhanDebugScheduleResult {
  const AdhanDebugScheduleResult({
    required this.notificationPermissionGranted,
    required this.exactAlarmAvailable,
    required this.nativeScheduleSuccess,
    required this.fallbackScheduled,
  });

  const AdhanDebugScheduleResult.native({
    required bool exactAlarmAvailable,
  }) : this(
         notificationPermissionGranted: true,
         exactAlarmAvailable: exactAlarmAvailable,
         nativeScheduleSuccess: true,
         fallbackScheduled: false,
       );

  const AdhanDebugScheduleResult.fallback({
    required bool exactAlarmAvailable,
  }) : this(
         notificationPermissionGranted: true,
         exactAlarmAvailable: exactAlarmAvailable,
         nativeScheduleSuccess: false,
         fallbackScheduled: true,
       );

  const AdhanDebugScheduleResult.blocked({
    bool notificationPermissionGranted = false,
    bool exactAlarmAvailable = false,
  }) : this(
         notificationPermissionGranted: notificationPermissionGranted,
         exactAlarmAvailable: exactAlarmAvailable,
         nativeScheduleSuccess: false,
         fallbackScheduled: false,
       );

  final bool notificationPermissionGranted;
  final bool exactAlarmAvailable;
  final bool nativeScheduleSuccess;
  final bool fallbackScheduled;

  bool get scheduled => nativeScheduleSuccess || fallbackScheduled;
}
