import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../telemetry/startup_perf_log.dart';
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
  static WidgetsBindingObserver? _metricsObserver;

  /// Overrides the Android platform check so host tests can exercise the
  /// native splash MethodChannel paths.
  @visibleForTesting
  static bool? debugIsAndroidOverride;

  /// Overrides the Flutter-view size check used before releasing the first
  /// frame (host tests for the 0×0 cold-start path).
  @visibleForTesting
  static bool Function()? debugHasNonZeroFlutterViewOverride;

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
    StartupPerfLog.log('first_frame_defer');
    _releaseFailsafeTimer = Timer(releaseFailsafeTimeout, () {
      if (_released) {
        return;
      }
      firstFrameLog(
        'FAILSAFE: first frame still deferred after '
        '${releaseFailsafeTimeout.inSeconds}s — forcing release',
      );
      StartupPerfLog.log(
        'first_frame_release_failsafe',
        detail: 'timeout_s=${releaseFailsafeTimeout.inSeconds}',
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
      // Avoid invoking the native splash channel from the failsafe path: the
      // engine/activity handshake may still be incomplete (FLUTTER-A4 class).
      release(notifyNativeSplash: false);
    });
  }

  /// Paints the first frame and dismisses the Android 12 splash without animation.
  static void release({bool notifyNativeSplash = true}) {
    _releaseFailsafeTimer?.cancel();
    _releaseFailsafeTimer = null;
    _detachMetricsObserver();
    if (_released) {
      firstFrameLog('allowFirstFrame skipped (already released)');
      return;
    }
    _released = true;
    if (_deferred) {
      WidgetsBinding.instance.allowFirstFrame();
      firstFrameLog('allowFirstFrame called (first Flutter frame may paint)');
      StartupPerfLog.log('first_frame_release');
    } else {
      firstFrameLog('allowFirstFrame skipped (defer was not used)');
    }
    if (notifyNativeSplash) {
      unawaited(notifyAndroidLaunchSplashReady());
    }
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
  ///
  /// On some OEM cold starts the first post-frame callback can run while the
  /// Flutter view is still 0×0 (see FLUTTER-A4 breadcrumbs). In that case we
  /// wait for [didChangeMetrics] before releasing.
  static void scheduleReleaseAfterFirstFrame() {
    firstFrameLog('scheduleReleaseAfterFirstFrame registered');
    StartupPerfLog.log('first_frame_release_scheduled');
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      firstFrameLog('frame callback: BootGate splash scheduled to build');
      StartupPerfLog.log('first_frame_boot_gate_build_scheduled');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        firstFrameLog('post-frame callback: BootGate splash built');
        StartupPerfLog.log('first_frame_boot_gate_built');
        if (!_hasNonZeroFlutterView()) {
          firstFrameLog(
            'post-frame callback: Flutter view is 0×0; waiting for metrics',
          );
          _attachMetricsObserver();
          return;
        }
        release();
      });
    });
  }

  static bool _hasNonZeroFlutterView() {
    final bool Function()? override = debugHasNonZeroFlutterViewOverride;
    if (override != null) {
      return override();
    }
    return WidgetsBinding.instance.platformDispatcher.views.any((
      FlutterView view,
    ) {
      return view.physicalSize.width > 0 && view.physicalSize.height > 0;
    });
  }

  static void _attachMetricsObserver() {
    _detachMetricsObserver();
    final _ReleaseOnNonZeroMetricsObserver observer =
        _ReleaseOnNonZeroMetricsObserver();
    _metricsObserver = observer;
    WidgetsBinding.instance.addObserver(observer);
  }

  static void _detachMetricsObserver() {
    final WidgetsBindingObserver? observer = _metricsObserver;
    if (observer == null) {
      return;
    }
    WidgetsBinding.instance.removeObserver(observer);
    _metricsObserver = null;
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
    } on MissingPluginException catch (error) {
      // Channel not registered yet / engine tearing down — treat as final so
      // we do not retry-spam. Android keep-on-screen failsafe still dismisses.
      firstFrameLog('native splash ready unavailable: $error');
    } on Object catch (error) {
      firstFrameLog('native splash ready failed: $error');
      _nativeSplashNotified = false;
    }
  }

  @visibleForTesting
  static void reset() {
    _releaseFailsafeTimer?.cancel();
    _releaseFailsafeTimer = null;
    _detachMetricsObserver();
    _deferred = false;
    _released = false;
    _nativeSplashNotified = false;
    debugIsAndroidOverride = null;
    debugHasNonZeroFlutterViewOverride = null;
  }
}

class _ReleaseOnNonZeroMetricsObserver extends WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    if (!LaunchFirstFrameGate._hasNonZeroFlutterView()) {
      return;
    }
    firstFrameLog('metrics changed: Flutter view is non-zero; releasing frame');
    LaunchFirstFrameGate.release();
  }
}
