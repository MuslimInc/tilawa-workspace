import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

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

  @override
  Future<void> initialize() async {
    try {
      // Disable collection in debug mode for development
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        recordFlutterError(details, fatal: true);
      };

      // Set up zone error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        recordError(error, stack, fatal: true);
        return true;
      };

      print('Crashlytics initialized successfully');
    } catch (e) {
      print('Crashlytics initialization error: $e');
    }
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
      print('Crashlytics recordError failed: $e');
    }
  }

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordFlutterFatalError(details);
    } catch (e) {
      print('Crashlytics recordFlutterError failed: $e');
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      print('Crashlytics setUserId failed: $e');
    }
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      print('Crashlytics setCustomKey failed: $e');
    }
  }

  @override
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      for (final entry in keys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    } catch (e) {
      print('Crashlytics setCustomKeys failed: $e');
    }
  }

  @override
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      print('Crashlytics log failed: $e');
    }
  }

  @override
  Future<bool> isCrashlyticsCollectionEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      print('Crashlytics isCrashlyticsCollectionEnabled failed: $e');
      return false;
    }
  }

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      print('Crashlytics setCrashlyticsCollectionEnabled failed: $e');
    }
  }

  @override
  Future<void> crash() async {
    try {
      _crashlytics.crash();
    } catch (e) {
      print('Crashlytics crash failed: $e');
    }
  }

  @override
  Future<void> setBreadcrumb(String message) async {
    try {
      await _crashlytics.log('Breadcrumb: $message');
    } catch (e) {
      print('Crashlytics setBreadcrumb failed: $e');
    }
  }
}
