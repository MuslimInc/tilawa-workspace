import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';

/// Whether voice recitation practice is exposed in the Mushaf reader.
///
/// Defaults to **false**. Enable in dev/QA with:
/// `--dart-define=TILAWA_LAUNCH_RECITATION_PRACTICE_ENABLED=true`
bool isRecitationPracticeEnabled() {
  if (!getIt.isRegistered<AppLaunchConfig>()) {
    return AppLaunchConfig.fromEnvironment().recitationPracticeEnabled;
  }
  return getIt<AppLaunchConfig>().recitationPracticeEnabled;
}
