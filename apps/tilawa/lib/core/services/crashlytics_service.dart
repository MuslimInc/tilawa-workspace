import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/bootstrap/app_error_guard.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/telemetry/crash_reporting_context.dart';

/// Centralized service for Firebase Crashlytics functionality
abstract class CrashlyticsService {
  /// Initialize Crashlytics with proper error handlers
  Future<void> initialize();

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Record a Flutter error
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  });

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId);

  /// Set custom key-value pairs for crash context
  Future<void> setCustomKey(String key, dynamic value);

  /// Set custom keys in batch
  Future<void> setCustomKeys(Map<String, dynamic> keys);

  /// Log a custom message
  Future<void> log(String message);

  /// Check if crashlytics collection is enabled
  Future<bool> isCrashlyticsCollectionEnabled();

  /// Enable or disable crashlytics collection
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);

  /// Force a test crash (for testing purposes)
  Future<void> crash();

  /// Set breadcrumb for debugging
  Future<void> setBreadcrumb(String message);
}

@Singleton(as: CrashlyticsService)
class FirebaseCrashlyticsServiceImpl implements CrashlyticsService {
  FirebaseCrashlyticsServiceImpl(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;
  static const String _loadingInterruptedMessage = 'Loading interrupted';
  static const String _abortMessage = 'abort';

  bool _isJustAudioInterruption(Object exception) {
    final String message = exception.toString();
    return message.contains(_loadingInterruptedMessage) ||
        message.contains(_abortMessage);
  }

  /// Returns true for network errors thrown by Flutter's image pipeline
  /// (e.g. NetworkImage failing to load a profile photo offline).
  /// These are not app crashes — they are expected when the device has no
  /// connectivity and should be recorded as non-fatal at most.
  bool _isNetworkImageError(Object exception) {
    final String message = exception.toString();
    return message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('ClientException') ||
        message.contains('HttpException') ||
        message.contains('Connection refused') ||
        message.contains('Connection reset');
  }

  @override
  Future<void> initialize() async {
    try {
      // Only collect crashes in release builds; disable in debug and profile.
      await _crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

      // The guard owns the global hooks (and already logs + presents errors);
      // attaching here flushes everything captured since process start.
      AppErrorGuard.attachReporter(
        onFlutterError: _reportFlutterError,
        onPlatformError: (Object error, StackTrace stack) {
          recordError(error, stack, fatal: true);
          return true;
        },
      );

      await setCustomKeys(await CrashReportingContext.crashlyticsKeys());

      logger.d('Crashlytics initialized successfully');
    } catch (e) {
      logger.d('Crashlytics initialization error: $e');
    }
  }

  void _reportFlutterError(FlutterErrorDetails details) {
    final Object exception = details.exception;
    if (_isJustAudioInterruption(exception)) {
      recordError(
        exception,
        details.stack,
        reason: 'just_audio interruption',
        fatal: false,
      );
      return;
    }
    // Network errors from image loading (e.g. profile photos offline) are
    // non-fatal and expected — don't pollute the fatal crash dashboard.
    if (_isNetworkImageError(exception)) {
      recordFlutterError(details, fatal: false);
      return;
    }
    recordFlutterError(details, fatal: true);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      logger.d('Crashlytics recordError failed: $e');
    }
  }

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    try {
      if (fatal) {
        await _crashlytics.recordFlutterFatalError(details);
      } else {
        await _crashlytics.recordFlutterError(details);
      }
    } catch (e) {
      logger.d('Crashlytics recordFlutterError failed: $e');
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      logger.d('Crashlytics setUserId failed: $e');
    }
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      logger.d('Crashlytics setCustomKey failed: $e');
    }
  }

  @override
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      for (final MapEntry<String, dynamic> entry in keys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    } catch (e) {
      logger.d('Crashlytics setCustomKeys failed: $e');
    }
  }

  @override
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      logger.d('Crashlytics log failed: $e');
    }
  }

  @override
  Future<bool> isCrashlyticsCollectionEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      logger.d('Crashlytics isCrashlyticsCollectionEnabled failed: $e');
      return false;
    }
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      logger.d('Crashlytics setCrashlyticsCollectionEnabled failed: $e');
    }
  }

  @override
  Future<void> crash() async {
    try {
      _crashlytics.crash();
    } catch (e) {
      logger.d('Crashlytics crash failed: $e');
    }
  }

  @override
  Future<void> setBreadcrumb(String message) async {
    try {
      await _crashlytics.log('Breadcrumb: $message');
    } catch (e) {
      logger.d('Crashlytics setBreadcrumb failed: $e');
    }
  }
}
