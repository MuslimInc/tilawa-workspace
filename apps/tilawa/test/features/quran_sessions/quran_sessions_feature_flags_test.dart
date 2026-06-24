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
    check(config.quranSessionsPaidBookingSandboxEnabled).isFalse();
    check(config.enabledCallProvidersCsv).equals('external,mock');

    final featureConfig = QuranSessionsFeatureConfig(
      quranSessionsEnabled: config.quranSessionsEnabled,
      teacherApplicationEnabled: config.teacherApplicationEnabled,
      teacherApplicationDiscoverability:
          TeacherApplicationDiscoverability.profileAndEmptyState,
      quranSessionsBookingEnabled: config.quranSessionsBookingEnabled,
      walletEnabled: config.quranSessionsPaidBookingSandboxEnabled,
    );
    check(featureConfig.showProfileTeacherEntry).isFalse();
    check(featureConfig.walletEnabled).isFalse();
  });

  test('paid sandbox flag enables wallet in feature config mapping', () {
    const config = AppLaunchConfig(
      quranSessionsPaidBookingSandboxEnabled: true,
    );
    final featureConfig = QuranSessionsFeatureConfig(
      quranSessionsEnabled: config.quranSessionsEnabled,
      teacherApplicationEnabled: config.teacherApplicationEnabled,
      teacherApplicationDiscoverability:
          TeacherApplicationDiscoverability.none,
      quranSessionsBookingEnabled: config.quranSessionsBookingEnabled,
      walletEnabled: config.quranSessionsPaidBookingSandboxEnabled,
    );
    check(featureConfig.walletEnabled).isTrue();
  });
}
