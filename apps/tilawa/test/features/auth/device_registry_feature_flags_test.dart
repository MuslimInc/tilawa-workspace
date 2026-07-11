import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/device_registry_feature_flags.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('multi-device login defaults to enabled in launch config', () {
    const AppLaunchConfig config = AppLaunchConfig();

    check(config.multiDeviceLoginEnabled).isTrue();
  });

  test(
    'isMultiDeviceLoginEnabled reads override from injected launch config',
    () async {
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(multiDeviceLoginEnabled: false),
      );

      check(isMultiDeviceLoginEnabled()).isFalse();

      await getIt.reset();
      getIt.registerSingleton<AppLaunchConfig>(
        const AppLaunchConfig(multiDeviceLoginEnabled: true),
      );

      check(isMultiDeviceLoginEnabled()).isTrue();
    },
  );
}
