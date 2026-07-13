import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';

void main() {
  test('smart khatma defaults to disabled in launch config', () {
    const AppLaunchConfig config = AppLaunchConfig();

    expect(config.smartKhatmaEnabled, isFalse);
    expect(config.wirdWidgetEnabled, isFalse);
  });

  test('Wird widget has a separate rollout switch', () {
    const AppLaunchConfig config = AppLaunchConfig(
      smartKhatmaEnabled: true,
      wirdWidgetEnabled: true,
    );

    expect(config.smartKhatmaEnabled, isTrue);
    expect(config.wirdWidgetEnabled, isTrue);
  });
}
