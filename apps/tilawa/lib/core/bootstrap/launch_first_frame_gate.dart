import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'first_frame_log.dart';

/// Holds the first Flutter frame until [release] so cold start shows the launch
/// splash immediately instead of a blank or native handoff frame.
abstract final class LaunchFirstFrameGate {
  static bool _deferred = false;
  static bool _released = false;
  static bool _nativeSplashNotified = false;

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
  }

  /// Paints the first frame and dismisses the Android 12 splash without animation.
  static void release() {
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
    if (kIsWeb || !Platform.isAndroid) {
      firstFrameLog('native splash ready skipped (not Android)');
      return;
    }
    firstFrameLog('native splash ready → MethodChannel(com.tilawa.app/launch_splash)');
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
    _deferred = false;
    _released = false;
    _nativeSplashNotified = false;
  }
}
