import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Whether the daily Today Plan card is exposed on the home dashboard.
///
/// Defaults to **false**. Enable in dev/QA with:
/// `--dart-define=TILAWA_LAUNCH_TODAY_PLAN_ENABLED=true`
bool isTodayPlanEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return AppLaunchConfig.fromEnvironment().todayPlanEnabled;
  }
  return getIt<AppLaunchConfig>().todayPlanEnabled;
}
