import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

import 'domain/entities/quran_sessions_platform_config.dart';
import 'quran_sessions_platform_config_store.dart';

/// Resolves [QuranSessionsFeatureConfig] from Admin/Firestore runtime config.
///
/// Admin config wins over [AppLaunchConfig]. When no cached/admin config
/// exists, the app fails closed with [QuranSessionsPlatformConfig.safeFallback].
QuranSessionsFeatureConfig quranSessionsFeatureConfig() {
  final AppLaunchConfig config = getIt.isRegistered<AppLaunchConfig>()
      ? getIt<AppLaunchConfig>()
      : AppLaunchConfig.fromEnvironment();
  final platformConfig = quranSessionsEffectivePlatformConfig();
  return QuranSessionsFeatureConfig(
    quranSessionsEnabled: platformConfig.quranSessionsEnabled,
    learnQuranStudentFeatureEnabled: platformConfig.studentEntryEnabled,
    teacherApplicationEntryEnabled:
        platformConfig.teacherApplicationEntryEnabled,
    homeTeacherApplicationCardEnabled:
        platformConfig.homeTeacherApplicationCardEnabled,
    teacherApplicationFormUrl: config.teacherApplicationFormUrl,
    teacherApplicationEnabled: platformConfig.teacherApplicationEnabled,
    teacherApplicationDiscoverability: _discoverabilityFromString(
      platformConfig.teacherApplicationDiscoverability,
    ),
    quranSessionsBookingEnabled: platformConfig.bookingEnabled,
    walletEnabled: platformConfig.walletEnabled,
  );
}

QuranSessionsPlatformConfig quranSessionsEffectivePlatformConfig({
  QuranSessionsPlatformConfig? fallback,
}) {
  final cachedConfig = getIt.isRegistered<QuranSessionsPlatformConfigStore>()
      ? getIt<QuranSessionsPlatformConfigStore>().config
      : null;
  if (cachedConfig != null) {
    return cachedConfig;
  }

  return fallback ?? QuranSessionsPlatformConfig.safeFallback;
}

TeacherApplicationDiscoverability _discoverabilityFromString(String value) {
  return switch (value) {
    'profileOnly' => TeacherApplicationDiscoverability.profileOnly,
    'profileAndEmptyState' =>
      TeacherApplicationDiscoverability.profileAndEmptyState,
    _ => TeacherApplicationDiscoverability.none,
  };
}
