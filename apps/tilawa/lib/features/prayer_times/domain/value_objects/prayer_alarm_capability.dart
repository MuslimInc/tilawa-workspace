import 'package:equatable/equatable.dart';

/// Snapshot of the device's capability to deliver prayer alarms.
///
/// `canScheduleExact` reflects Android 12+ `SCHEDULE_EXACT_ALARM` /
/// `USE_EXACT_ALARM`. `hasNotificationPermission` reflects the Android 13+
/// `POST_NOTIFICATIONS` runtime permission. Both are `true` on platforms /
/// versions where the corresponding permission is auto-granted or absent.
class PrayerAlarmCapability extends Equatable {
  const PrayerAlarmCapability({
    required this.canScheduleExact,
    required this.hasNotificationPermission,
  });

  final bool canScheduleExact;
  final bool hasNotificationPermission;

  bool get isFullyCapable => canScheduleExact && hasNotificationPermission;

  @override
  List<Object?> get props => [canScheduleExact, hasNotificationPermission];
}
