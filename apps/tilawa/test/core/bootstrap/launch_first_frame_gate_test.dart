import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/launch_first_frame_gate.dart';

void main() {
  tearDown(LaunchFirstFrameGate.reset);

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
}
