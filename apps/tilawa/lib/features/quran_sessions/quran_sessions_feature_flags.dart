import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Resolves [QuranSessionsFeatureConfig] from [AppLaunchConfig].
///
/// Defaults (production):
/// - [quranSessionsEnabled]: true
/// - [teacherApplicationEnabled]: false until MVO ops ready
/// - [teacherApplicationDiscoverability]: profileAndEmptyState when apply enabled
/// - [quranSessionsBookingEnabled]: false until approved supply exists
QuranSessionsFeatureConfig quranSessionsFeatureConfig() {
  final AppLaunchConfig config = getIt.isRegistered<AppLaunchConfig>()
      ? getIt<AppLaunchConfig>()
      : AppLaunchConfig.fromEnvironment();
  return QuranSessionsFeatureConfig(
    quranSessionsEnabled: config.quranSessionsEnabled,
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
