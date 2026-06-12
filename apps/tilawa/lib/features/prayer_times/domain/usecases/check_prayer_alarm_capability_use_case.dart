import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../../../../core/services/notification_permission_service.dart';
import '../services/adhan_alarm_player_interface.dart';
import '../services/prayer_adhan_notification_service_interface.dart';
import '../value_objects/prayer_alarm_capability.dart';

/// Manufacturer strings (lowercase) of OEM ROMs that require an additional
/// per-app autostart whitelist. Generic Android settings cannot toggle this
/// — we can only surface guidance to the user.
const Set<String> _autostartOems = <String>{
  'xiaomi',
  'redmi',
  'poco',
  'oppo',
  'realme',
  'oneplus',
  'vivo',
  'iqoo',
  'huawei',
  'honor',
  'meizu',
  'asus',
  // Transsion brands (Infinix, Tecno, Itel) — aggressive background limits.
  'infinix',
  'tecno',
  'itel',
};

/// Checks the device's capability to deliver prayer alarms reliably.
///
/// Combines exact-alarm scheduling (Android 12+), runtime notification
/// permission (Android 13+), and OEM autostart restrictions into a single value object
/// the BLoC and UI can reason about. All checks are fail-soft: a failure in
/// one defaults to the safe value so the UI surfaces the degraded state
/// rather than crashing.
@injectable
class CheckPrayerAlarmCapabilityUseCase {
  const CheckPrayerAlarmCapabilityUseCase(
    this._service,
    this._permissions,
    this._adhanPlayer,
  );

  final IPrayerAdhanNotificationService _service;
  final NotificationPermissionService _permissions;
  final IAdhanAlarmPlayer _adhanPlayer;

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

    bool isIgnoringBatteryOptimizations;
    try {
      isIgnoringBatteryOptimizations =
          await _adhanPlayer.isIgnoringBatteryOptimizations();
    } catch (_) {
      isIgnoringBatteryOptimizations = true;
    }

    bool oemRequiresAutostart = false;
    try {
      final String? mfr = await _adhanPlayer.manufacturer();
      if (mfr != null) {
        oemRequiresAutostart = _autostartOems.contains(mfr.toLowerCase());
      }
    } catch (_) {}

    return Right(
      PrayerAlarmCapability(
        canScheduleExact: canScheduleExact,
        hasNotificationPermission: hasNotificationPermission,
        isIgnoringBatteryOptimizations: isIgnoringBatteryOptimizations,
        oemRequiresAutostart: oemRequiresAutostart,
      ),
    );
  }
}
