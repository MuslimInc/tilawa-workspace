import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Whether Smart Khatma is exposed on the home dashboard and reader.
///
/// The production environment default is enabled for the release candidate.
/// Tests and bootstrap-free contexts remain disabled until [AppLaunchConfig]
/// is registered.
bool isSmartKhatmaEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return false;
  }
  return getIt<AppLaunchConfig>().smartKhatmaEnabled;
}

/// Whether the Android Daily Wird launcher widget is exposed and synchronized.
///
/// This is intentionally independent from [isSmartKhatmaEnabled] so the native
/// surface has a dedicated rollout and rollback switch.
bool isWirdWidgetEnabled() {
  final AppLaunchConfig config = getIt.isRegistered<AppLaunchConfig>()
      ? getIt<AppLaunchConfig>()
      : AppLaunchConfig.fromEnvironment();
  return config.smartKhatmaEnabled && config.wirdWidgetEnabled;
}
