import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../../../../core/services/notification_permission_service.dart';
import '../services/prayer_adhan_notification_service_interface.dart';
import '../value_objects/prayer_alarm_capability.dart';

/// Checks the device's capability to deliver prayer alarms.
///
/// Combines two independent capability axes — exact-alarm scheduling
/// (Android 12+) and runtime notification permission (Android 13+) — into a
/// single value object the BLoC and UI can reason about. Both checks are
/// fail-soft: a failure in one defaults to `false` so the UI surfaces the
/// degraded state rather than crashing.
@injectable
class CheckPrayerAlarmCapabilityUseCase {
  const CheckPrayerAlarmCapabilityUseCase(this._service, this._permissions);

  final IPrayerAdhanNotificationService _service;
  final NotificationPermissionService _permissions;

  Future<Either<Failure, PrayerAlarmCapability>> call() async {
    bool canScheduleExact;
    try {
      canScheduleExact = await _service.canScheduleExactAlarms();
    } catch (_) {
      canScheduleExact = false;
    }

    bool hasNotificationPermission;
    try {
      hasNotificationPermission = await _permissions.isPermissionGranted();
    } catch (_) {
      hasNotificationPermission = false;
    }

    return Right(
      PrayerAlarmCapability(
        canScheduleExact: canScheduleExact,
        hasNotificationPermission: hasNotificationPermission,
      ),
    );
  }
}
