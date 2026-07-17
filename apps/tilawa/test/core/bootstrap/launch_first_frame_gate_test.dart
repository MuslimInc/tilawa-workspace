import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/launch_first_frame_gate.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel launchSplashChannel = MethodChannel(
    'com.tilawa.app/launch_splash',
  );

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      launchSplashChannel,
      null,
    );
    LaunchFirstFrameGate.reset();
  });

  test('release after defer allows frames', () {
    LaunchFirstFrameGate.defer();
    LaunchFirstFrameGate.release();
    expect(WidgetsBinding.instance.sendFramesToEngine, isTrue);
  });

  test('release is idempotent', () {
    LaunchFirstFrameGate.defer();
    LaunchFirstFrameGate.release();
    LaunchFirstFrameGate.release();
    expect(WidgetsBinding.instance.sendFramesToEngine, isTrue);
  });

  test('notifyAndroidLaunchSplashReady is idempotent', () async {
    LaunchFirstFrameGate.reset();
    await LaunchFirstFrameGate.notifyAndroidLaunchSplashReady();
    await LaunchFirstFrameGate.notifyAndroidLaunchSplashReady();
    expect(LaunchFirstFrameGate.reset, returnsNormally);
  });

  test(
    'notifyAndroidLaunchSplashReady treats missing native handler as final',
    () async {
      LaunchFirstFrameGate.debugIsAndroidOverride = true;
      var calls = 0;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        launchSplashChannel,
        (_) async {
          calls++;
          throw MissingPluginException();
        },
      );

      await LaunchFirstFrameGate.notifyAndroidLaunchSplashReady();
      await LaunchFirstFrameGate.notifyAndroidLaunchSplashReady();

      expect(calls, 1);
    },
  );

  testWidgets(
    'scheduleReleaseAfterFirstFrame waits for non-zero Flutter view',
    (WidgetTester tester) async {
      var viewReady = false;
      LaunchFirstFrameGate.debugHasNonZeroFlutterViewOverride = () => viewReady;

      LaunchFirstFrameGate.defer();
      expect(WidgetsBinding.instance.sendFramesToEngine, isFalse);

      LaunchFirstFrameGate.scheduleReleaseAfterFirstFrame();
      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        WidgetsBinding.instance.sendFramesToEngine,
        isFalse,
        reason: 'must not release while Flutter view reports 0×0',
      );

      viewReady = true;
      binding.handleMetricsChanged();
      await tester.pump();

      expect(WidgetsBinding.instance.sendFramesToEngine, isTrue);
    },
  );

  testWidgets(
    'scheduleReleaseAfterFirstFrame releases on first post-frame when view ready',
    (WidgetTester tester) async {
      LaunchFirstFrameGate.debugHasNonZeroFlutterViewOverride = () => true;

      LaunchFirstFrameGate.defer();
      expect(WidgetsBinding.instance.sendFramesToEngine, isFalse);

      LaunchFirstFrameGate.scheduleReleaseAfterFirstFrame();
      await tester.pumpWidget(const SizedBox.shrink());

      expect(WidgetsBinding.instance.sendFramesToEngine, isTrue);
    },
  );
}
