import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:luciq_flutter/luciq_flutter.dart';

import '../../main.dart';

/// Abstract interface for Luciq bug reporting and crash analytics
abstract class LuciqService {
  /// Initialize Luciq SDK
  /// Must be called before runApp() to capture all crashes
  Future<void> initialize();

  /// Show Luciq dialog manually
  void show();

  /// Identify the current user
  Future<void> identifyUser(String userId, {String? email, String? name});

  /// Log out the current user
  Future<void> logoutUser();

  /// Log a custom event
  void logEvent(String eventName);

  /// Log a user action (breadcrumb)
  void logUserAction(String action);

  /// Set custom user attribute
  Future<void> setUserAttribute(String key, String value);

  /// Report handled exception
  void reportException(dynamic exception, StackTrace stackTrace);

  /// Enable or disable Luciq
  Future<void> setEnabled(bool enabled);

  /// Show/hide in-app notifications
  Future<void> setInAppNotificationsEnabled(bool enabled);

  /// Add tags to the bug report
  void addTags(List<String> tags);

  /// Set custom data to be attached to bug reports
  void setCustomData(String key, String value);
}

@Singleton(as: LuciqService)
class LuciqServiceImpl implements LuciqService {
  LuciqServiceImpl();

  bool _isInitialized = false;

  // Luciq Production token
  static const String _luciqToken = 'f4ce50b3e7386a09d7b6a12eeb02c1b4';
  // Luciq Staging token
  static const String _luciqTokenStaging = '56e6441a439ff3d576810b01782b97b3';

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('Luciq already initialized');
      return;
    }

    try {
      // Initialize Luciq
      await Luciq.init(
        token: kDebugMode ? _luciqTokenStaging : _luciqToken,
        invocationEvents: [InvocationEvent.shake, InvocationEvent.screenshot],
      );

      // Configure Luciq settings
      await _configureLuciq();

      _isInitialized = true;
      logger.d('Luciq initialized successfully');
    } catch (e) {
      logger.d('Luciq initialization error: $e');
    }
  }

  /// Configure Luciq settings
  Future<void> _configureLuciq() async {
    try {
      // Enable/disable based on build mode
      await Luciq.setEnabled(!kDebugMode);

      // Configure report types
      await BugReporting.setReportTypes([ReportType.bug, ReportType.feedback]);

      // Enable crash reporting
      await CrashReporting.setEnabled(true);

      // Configure theme
      await Luciq.setColorTheme(ColorTheme.dark);

      logger.d('Luciq configured successfully');
    } catch (e) {
      logger.d('Luciq configuration error: $e');
    }
  }

  @override
  void show() {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot show dialog');
      return;
    }

    try {
      Luciq.show();
    } catch (e) {
      logger.d('Luciq show error: $e');
    }
  }

  @override
  Future<void> identifyUser(
    String userId, {
    String? email,
    String? name,
  }) async {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot identify user');
      return;
    }

    try {
      await Luciq.identifyUser(userId, email, name);
      logger.d('Luciq user identified: $userId');
    } catch (e) {
      logger.d('Luciq identifyUser error: $e');
    }
  }

  @override
  Future<void> logoutUser() async {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot logout user');
      return;
    }

    try {
      // Clear user identity by setting empty values
      await Luciq.identifyUser('');
      logger.d('Luciq user logged out');
    } catch (e) {
      logger.d('Luciq logoutUser error: $e');
    }
  }

  @override
  void logEvent(String eventName) {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot log event');
      return;
    }

    try {
      Luciq.logUserEvent(eventName);
      logger.d('Luciq event logged: $eventName');
    } catch (e) {
      logger.d('Luciq logEvent error: $e');
    }
  }

  @override
  void logUserAction(String action) {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot log user action');
      return;
    }

    try {
      // Log as custom event instead
      Luciq.logUserEvent(action);
      logger.d('Luciq user action logged: $action');
    } catch (e) {
      logger.d('Luciq logUserAction error: $e');
    }
  }

  @override
  Future<void> setUserAttribute(String key, String value) async {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot set user attribute');
      return;
    }

    try {
      await Luciq.setUserAttribute(key, value);
      logger.d('Luciq user attribute set: $key = $value');
    } catch (e) {
      logger.d('Luciq setUserAttribute error: $e');
    }
  }

  @override
  void reportException(dynamic exception, StackTrace stackTrace) {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot report exception');
      return;
    }

    try {
      CrashReporting.reportCrash(exception, stackTrace);
      logger.d('Luciq exception reported: $exception');
    } catch (e) {
      logger.d('Luciq reportException error: $e');
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot set enabled state');
      return;
    }

    try {
      await Luciq.setEnabled(enabled);
      logger.d('Luciq enabled: $enabled');
    } catch (e) {
      logger.d('Luciq setEnabled error: $e');
    }
  }

  @override
  Future<void> setInAppNotificationsEnabled(bool enabled) async {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot set notifications state');
      return;
    }

    try {
      await Replies.setInAppNotificationsEnabled(enabled);
      logger.d('Luciq in-app notifications enabled: $enabled');
    } catch (e) {
      logger.d('Luciq setInAppNotificationsEnabled error: $e');
    }
  }

  @override
  void addTags(List<String> tags) {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot add tags');
      return;
    }

    try {
      Luciq.appendTags(tags);
      logger.d('Luciq tags added: $tags');
    } catch (e) {
      logger.d('Luciq addTags error: $e');
    }
  }

  @override
  void setCustomData(String key, String value) {
    if (!_isInitialized) {
      logger.d('Luciq not initialized, cannot set custom data');
      return;
    }

    try {
      Luciq.setUserData(value);
      logger.d('Luciq custom data set: $key = $value');
    } catch (e) {
      logger.d('Luciq setCustomData error: $e');
    }
  }
}
