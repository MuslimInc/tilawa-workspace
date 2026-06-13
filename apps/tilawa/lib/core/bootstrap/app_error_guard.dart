import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Process-wide error capture, installed in `main()` before anything else.
///
/// Crashlytics initialization is deliberately deferred past the first frame
/// (see `AppStartupTasks`), which previously left the whole startup window
/// without a [ui.PlatformDispatcher.onError] handler and with a log-only
/// [FlutterError.onError]. The guard owns both global hooks for the entire
/// process lifetime: it logs immediately, buffers errors raised before the
/// crash reporter is ready, and replays the buffer once [attachReporter]
/// is called. Reporters never assign the global hooks directly, so handlers
/// can no longer silently overwrite each other.
abstract final class AppErrorGuard {
  /// Buffer keeps the earliest errors — those closest to the root cause of a
  /// broken startup — and drops later ones once full.
  static const int maxBufferedErrors = 30;

  static bool _installed = false;
  static FlutterExceptionHandler? _reporterFlutterHandler;
  static ui.ErrorCallback? _reporterPlatformHandler;
  static final List<FlutterErrorDetails> _bufferedFlutterErrors =
      <FlutterErrorDetails>[];
  static final List<(Object, StackTrace)> _bufferedPlatformErrors =
      <(Object, StackTrace)>[];

  /// Installs the global error hooks. Idempotent; safe to call again.
  static void install() {
    if (_installed) {
      return;
    }
    _installed = true;
    FlutterError.onError = _handleFlutterError;
    ui.PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  /// Wires the crash reporter in and flushes errors captured before it was
  /// ready. Called from `CrashlyticsService.initialize()`.
  static void attachReporter({
    required FlutterExceptionHandler onFlutterError,
    required ui.ErrorCallback onPlatformError,
  }) {
    install();
    _reporterFlutterHandler = onFlutterError;
    _reporterPlatformHandler = onPlatformError;

    final List<FlutterErrorDetails> flutterBacklog =
        List<FlutterErrorDetails>.of(
          _bufferedFlutterErrors,
        );
    final List<(Object, StackTrace)> platformBacklog =
        List<(Object, StackTrace)>.of(_bufferedPlatformErrors);
    _bufferedFlutterErrors.clear();
    _bufferedPlatformErrors.clear();

    for (final FlutterErrorDetails details in flutterBacklog) {
      onFlutterError(details);
    }
    for (final (Object error, StackTrace stackTrace) in platformBacklog) {
      onPlatformError(error, stackTrace);
    }
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    logger.e(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);

    final FlutterExceptionHandler? reporter = _reporterFlutterHandler;
    if (reporter != null) {
      reporter(details);
    } else if (_bufferedFlutterErrors.length < maxBufferedErrors) {
      _bufferedFlutterErrors.add(details);
    }
  }

  static bool _handlePlatformError(Object error, StackTrace stackTrace) {
    logger.e(
      'Uncaught platform error: $error',
      error: error,
      stackTrace: stackTrace,
    );

    final ui.ErrorCallback? reporter = _reporterPlatformHandler;
    if (reporter != null) {
      return reporter(error, stackTrace);
    }
    if (_bufferedPlatformErrors.length < maxBufferedErrors) {
      _bufferedPlatformErrors.add((error, stackTrace));
    }
    return true;
  }

  /// Clears installed state and buffers. Does not restore the previous global
  /// hooks — tests must save and restore those themselves.
  @visibleForTesting
  static void resetForTesting() {
    _installed = false;
    _reporterFlutterHandler = null;
    _reporterPlatformHandler = null;
    _bufferedFlutterErrors.clear();
    _bufferedPlatformErrors.clear();
  }
}
