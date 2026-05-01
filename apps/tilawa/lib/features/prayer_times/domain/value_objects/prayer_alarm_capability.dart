import 'package:equatable/equatable.dart';

/// Snapshot of the device's capability to deliver prayer alarms.
///
/// `canScheduleExact` reflects Android 12+ `SCHEDULE_EXACT_ALARM` /
/// `USE_EXACT_ALARM`. `hasNotificationPermission` reflects the Android 13+
/// `POST_NOTIFICATIONS` runtime permission. `isIgnoringBatteryOptimizations`
/// reflects whether the user has whitelisted the app from Doze (without
/// this, alarms are deferred when the device idles, especially overnight).
/// `oemRequiresAutostart` is `true` on aggressive OEM ROMs (Xiaomi, Oppo,
/// Vivo, Huawei, Honor) where the app must additionally be added to the
/// vendor's autostart/protected-app list — that screen is not directly
/// reachable from a generic intent on every device, so we surface guidance
/// instead of attempting a direct request.
///
/// Every flag is `true` on platforms / versions where the corresponding
/// permission is auto-granted, absent, or not applicable.
class PrayerAlarmCapability extends Equatable {
  const PrayerAlarmCapability({
    required this.canScheduleExact,
    required this.hasNotificationPermission,
    this.isIgnoringBatteryOptimizations = true,
    this.oemRequiresAutostart = false,
  });

  final bool canScheduleExact;
  final bool hasNotificationPermission;
  final bool isIgnoringBatteryOptimizations;
  final bool oemRequiresAutostart;

  bool get isFullyCapable =>
      canScheduleExact &&
      hasNotificationPermission &&
      isIgnoringBatteryOptimizations;

  @override
  List<Object?> get props => [
    canScheduleExact,
    hasNotificationPermission,
    isIgnoringBatteryOptimizations,
    oemRequiresAutostart,
  ];
}
