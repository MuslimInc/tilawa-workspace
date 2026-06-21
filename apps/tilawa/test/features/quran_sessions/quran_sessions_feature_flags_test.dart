import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';

void main() {
  test('AppLaunchConfig defaults match Option D production suggestion', () {
    const config = AppLaunchConfig();
    check(config.quranSessionsEnabled).isTrue();
    check(config.teacherApplicationEnabled).isFalse();
    check(
      config.teacherApplicationDiscoverability,
    ).equals('profileAndEmptyState');
    check(config.quranSessionsBookingEnabled).isFalse();

    final featureConfig = QuranSessionsFeatureConfig(
      quranSessionsEnabled: config.quranSessionsEnabled,
      teacherApplicationEnabled: config.teacherApplicationEnabled,
      teacherApplicationDiscoverability:
          TeacherApplicationDiscoverability.profileAndEmptyState,
      quranSessionsBookingEnabled: config.quranSessionsBookingEnabled,
    );
    check(featureConfig.showProfileTeacherEntry).isFalse();
  });
}
