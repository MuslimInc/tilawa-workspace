import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';

void main() {
  test('fromEnvironment learn quran flag matches compile-time dart-define', () {
    const bool expected = bool.fromEnvironment(
      'TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED',
    );
    final AppLaunchConfig config = AppLaunchConfig.fromEnvironment();
    check(config.learnQuranStudentFeatureEnabled).equals(expected);

    final QuranSessionsFeatureConfig featureConfig = QuranSessionsFeatureConfig(
      quranSessionsEnabled: config.quranSessionsEnabled,
      learnQuranStudentFeatureEnabled: config.learnQuranStudentFeatureEnabled,
    );
    check(featureConfig.showLearnQuranStudentExperience).equals(
      config.quranSessionsEnabled && expected,
    );
  });
}
