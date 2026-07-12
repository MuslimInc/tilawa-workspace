import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Whether Smart Khatma is exposed on the home dashboard and reader.
///
/// Defaults to **false**. Enable in dev/QA with:
/// `--dart-define=TILAWA_LAUNCH_SMART_KHATMA_ENABLED=true`
bool isSmartKhatmaEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return AppLaunchConfig.fromEnvironment().smartKhatmaEnabled;
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
