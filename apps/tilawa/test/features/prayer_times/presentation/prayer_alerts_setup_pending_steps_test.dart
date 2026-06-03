import 'package:test/test.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:tilawa/features/prayer_times/presentation/prayer_alerts_setup_pending_steps.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';

void main() {
  test('includes location before notification steps', () {
    final List<PrayerAlertsPermissionStep> steps = prayerAlertsSetupPendingSteps(
      hasLocationPermission: false,
      capability: const PrayerAlarmCapability(
        canScheduleExact: false,
        hasNotificationPermission: false,
      ),
    );

    expect(steps.first, PrayerAlertsPermissionStep.location);
    expect(steps, contains(PrayerAlertsPermissionStep.notifications));
  });

  test('returns empty when all grants present', () {
    final List<PrayerAlertsPermissionStep> steps = prayerAlertsSetupPendingSteps(
      hasLocationPermission: true,
      capability: const PrayerAlarmCapability(
        canScheduleExact: true,
        hasNotificationPermission: true,
      ),
    );

    expect(steps, isEmpty);
  });
}
