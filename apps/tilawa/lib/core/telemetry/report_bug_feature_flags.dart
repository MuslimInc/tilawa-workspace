import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Whether Settings "Report a bug" and Sentry feedback prompts are exposed.
///
/// Defaults to **false**. Enable in builds with:
/// `--dart-define=TILAWA_LAUNCH_REPORT_BUG_ENABLED=true`
bool isReportBugEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return AppLaunchConfig.fromEnvironment().reportBugEnabled;
  }
  return getIt<AppLaunchConfig>().reportBugEnabled;
}
