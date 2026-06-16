import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';

void main() {
  test('smart khatma defaults to disabled in launch config', () {
    const AppLaunchConfig config = AppLaunchConfig();

    expect(config.smartKhatmaEnabled, isFalse);
  });
}
