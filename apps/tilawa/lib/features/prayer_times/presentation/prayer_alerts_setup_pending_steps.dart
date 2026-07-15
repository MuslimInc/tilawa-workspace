import 'dart:io';

import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';

/// Builds the ordered permission steps for [PrayerAlertsPermissionFlow].
List<PrayerAlertsPermissionStep> prayerAlertsSetupPendingSteps({
  required bool hasLocationPermission,
  PrayerAlarmCapability? capability,
}) {
  final List<PrayerAlertsPermissionStep> steps = <PrayerAlertsPermissionStep>[];

  if (!hasLocationPermission) {
    steps.add(PrayerAlertsPermissionStep.location);
  }

  if (capability == null) {
    return steps;
  }

  if (!capability.hasNotificationPermission) {
    steps.add(PrayerAlertsPermissionStep.notifications);
  }

  if (!Platform.isAndroid) {
    return steps;
  }

  if (!capability.canScheduleExact) {
    steps.add(PrayerAlertsPermissionStep.exactAlarm);
  }
  // Battery optimization step temporarily disabled from the first-run wizard.
  // if (!capability.isIgnoringBatteryOptimizations) {
  //   steps.add(PrayerAlertsPermissionStep.batteryOptimization);
  // }
  if (capability.oemRequiresAutostart) {
    steps.add(PrayerAlertsPermissionStep.oemAutostart);
  }

  return steps;
}
