import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/telemetry/report_bug_feature_flags.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('report bug defaults to disabled in launch config', () {
    const AppLaunchConfig config = AppLaunchConfig();

    expect(config.reportBugEnabled, isFalse);
  });

  test('isReportBugEnabled reads registered launch config', () {
    getIt.registerSingleton<AppLaunchConfig>(
      const AppLaunchConfig(reportBugEnabled: true),
    );

    expect(isReportBugEnabled(), isTrue);
  });
}
