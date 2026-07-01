import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Resolves [QuranSessionsFeatureConfig] from [AppLaunchConfig].
///
/// Defaults (production const / `play_production` distribution):
/// - [quranSessionsEnabled]: true
/// - [learnQuranStudentFeatureEnabled]: **false** — student hub hidden in prod
/// - [teacherApplicationEntryEnabled]: **false** — Google Form entry opt-in
/// - [homeTeacherApplicationCardEnabled]: **false**
/// - [teacherApplicationEnabled]: false until MVO ops ready
/// - [teacherApplicationDiscoverability]: profileAndEmptyState when apply enabled
/// - [quranSessionsBookingEnabled]: **false** — production kill switch; do not
///   flip via ops. Enable per build with
///   `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true` or use a
///   non-`play_production` [TILAWA_DISTRIBUTION] (local/staging default ON via
///   [AppLaunchConfig.fromEnvironment]). Widget tests register
///   [AppLaunchConfig(quranSessionsBookingEnabled: true)] in get_it.
QuranSessionsFeatureConfig quranSessionsFeatureConfig() {
  final AppLaunchConfig config = getIt.isRegistered<AppLaunchConfig>()
      ? getIt<AppLaunchConfig>()
      : AppLaunchConfig.fromEnvironment();
  return QuranSessionsFeatureConfig(
    quranSessionsEnabled: config.quranSessionsEnabled,
    learnQuranStudentFeatureEnabled: config.learnQuranStudentFeatureEnabled,
    teacherApplicationEntryEnabled: config.teacherApplicationEntryEnabled,
    homeTeacherApplicationCardEnabled: config.homeTeacherApplicationCardEnabled,
    teacherApplicationFormUrl: config.teacherApplicationFormUrl,
    teacherApplicationEnabled: config.teacherApplicationEnabled,
    teacherApplicationDiscoverability: _discoverabilityFromString(
      config.teacherApplicationDiscoverability,
    ),
    quranSessionsBookingEnabled: config.quranSessionsBookingEnabled,
    walletEnabled: config.quranSessionsPaidBookingSandboxEnabled,
  );
}

TeacherApplicationDiscoverability _discoverabilityFromString(String value) {
  return switch (value) {
    'profileOnly' => TeacherApplicationDiscoverability.profileOnly,
    'profileAndEmptyState' =>
      TeacherApplicationDiscoverability.profileAndEmptyState,
    _ => TeacherApplicationDiscoverability.none,
  };
}
