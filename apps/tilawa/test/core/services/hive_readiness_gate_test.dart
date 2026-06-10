import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/services/hive_readiness_gate.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  setUp(() {
    configureAppLaunch(launchConfig: const AppLaunchConfig(hiveInit: true));
    resetMemoizedInitFutures();
  });

  tearDown(() async {
    if (Hive.isBoxOpen(TasbeehConstants.storageBoxName)) {
      await Hive.box(TasbeehConstants.storageBoxName).close();
    }
  });

  test('ensureReady completes and allows hive box access', () async {
    final HiveReadinessGate gate = HiveReadinessGate();

    await gate.ensureReady();

    final box = await Hive.openBox(TasbeehConstants.storageBoxName);
    expect(box, isNotNull);
  });

  test('ensureReady is safe to call multiple times', () async {
    final HiveReadinessGate gate = HiveReadinessGate();

    await Future.wait<void>(<Future<void>>[
      gate.ensureReady(),
      gate.ensureReady(),
      gate.ensureReady(),
    ]);

    final box = await Hive.openBox(TasbeehConstants.storageBoxName);
    expect(box, isNotNull);
  });
}
