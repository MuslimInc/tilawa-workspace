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
