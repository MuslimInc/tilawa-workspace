import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';
import 'package:tilawa/router/prayer_alerts_permission_nav_extra.dart';

void main() {
  group('PrayerAlertsPermissionNavExtra', () {
    test('defaults continueToLoginOnFinish to false', () {
      const PrayerAlertsPermissionNavExtra extra =
          PrayerAlertsPermissionNavExtra();

      expect(extra.steps, isNull);
      expect(extra.continueToLoginOnFinish, isFalse);
    });

    test('stores pinned steps and login exit flag', () {
      const PrayerAlertsPermissionNavExtra extra =
          PrayerAlertsPermissionNavExtra(
            steps: <PrayerAlertsPermissionStep>[
              PrayerAlertsPermissionStep.location,
              PrayerAlertsPermissionStep.notifications,
            ],
            continueToLoginOnFinish: true,
          );

      expect(extra.steps, hasLength(2));
      expect(extra.continueToLoginOnFinish, isTrue);
    });
  });
}
