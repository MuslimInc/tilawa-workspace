import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../telemetry/startup_telemetry.dart';
import 'first_frame_log.dart';

/// Holds the first Flutter frame until [release] so cold start shows the launch
/// splash immediately instead of a blank or native handoff frame.
abstract final class LaunchFirstFrameGate {
  /// Failsafe: the normal release path depends on BootGate's frame callbacks
  /// actually running. If anything wedges before that (exception during the
  /// warm-up frame, vsync never delivered, runApp failing), the user would be
  /// stuck on the native launch window forever — force the release instead.
  static const Duration releaseFailsafeTimeout = Duration(seconds: 3);

  static bool _deferred = false;
  static bool _released = false;
  static bool _nativeSplashNotified = false;
  static Timer? _releaseFailsafeTimer;

  /// Overrides the Android platform check so host tests can exercise the
  /// native splash MethodChannel paths.
  @visibleForTesting
  static bool? debugIsAndroidOverride;

  /// Call once before [runApp] during bootstrap.
  static void defer() {
    if (_deferred) {
      firstFrameLog('deferFirstFrame skipped (already deferred)');
      return;
    }
    _deferred = true;
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.deferFirstFrame();
    firstFrameLog('deferFirstFrame enabled (frames held until release)');
    _releaseFailsafeTimer = Timer(releaseFailsafeTimeout, () {
      if (_released) {
        return;
      }
      firstFrameLog(
        'FAILSAFE: first frame still deferred after '
        '${releaseFailsafeTimeout.inSeconds}s — forcing release',
      );
      unawaited(
        StartupTelemetry.failure(
          'first_frame_release_failsafe',
          TimeoutException(
            'first frame never released by BootGate',
            releaseFailsafeTimeout,
          ),
          StackTrace.current,
          phase: 'first_frame_gate',
        ),
      );
      release();
    });
  }

  /// Paints the first frame and dismisses the Android 12 splash without animation.
  static void release() {
    _releaseFailsafeTimer?.cancel();
    _releaseFailsafeTimer = null;
    if (_released) {
      firstFrameLog('allowFirstFrame skipped (already released)');
      return;
    }
    _released = true;
    if (_deferred) {
      WidgetsBinding.instance.allowFirstFrame();
      firstFrameLog('allowFirstFrame called (first Flutter frame may paint)');
    } else {
      firstFrameLog('allowFirstFrame skipped (defer was not used)');
    }
    unawaited(notifyAndroidLaunchSplashReady());
  }

  /// Dismisses the Android 12 splash after the Flutter launch UI is painted.
  static Future<void> notifyAndroidLaunchSplashReady() async {
    if (_nativeSplashNotified) {
      firstFrameLog('native splash ready skipped (already notified)');
      return;
    }
    _nativeSplashNotified = true;
    await _invokeAndroidLaunchSplashReady();
  }

  /// Schedules [release] after the first frame containing [child] is built.
  static void scheduleReleaseAfterFirstFrame() {
    firstFrameLog('scheduleReleaseAfterFirstFrame registered');
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      firstFrameLog('frame callback: BootGate splash scheduled to build');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        firstFrameLog('post-frame callback: BootGate splash built');
        release();
      });
    });
  }

  static Future<void> _invokeAndroidLaunchSplashReady() async {
    final bool isAndroid =
        debugIsAndroidOverride ?? (!kIsWeb && Platform.isAndroid);
    if (!isAndroid) {
      firstFrameLog('native splash ready skipped (not Android)');
      return;
    }
    firstFrameLog(
      'native splash ready → MethodChannel(com.tilawa.app/launch_splash)',
    );
    try {
      await const MethodChannel(
        'com.tilawa.app/launch_splash',
      ).invokeMethod<void>('ready');
      firstFrameLog('native splash ready acknowledged');
    } on Object catch (error) {
      firstFrameLog('native splash ready failed: $error');
      _nativeSplashNotified = false;
    }
  }

  @visibleForTesting
  static void reset() {
    _releaseFailsafeTimer?.cancel();
    _releaseFailsafeTimer = null;
    _deferred = false;
    _released = false;
    _nativeSplashNotified = false;
    debugIsAndroidOverride = null;
  }
}
