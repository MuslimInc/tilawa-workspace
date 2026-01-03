import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../main.dart';

/// Abstract interface for AppsFlyer attribution and analytics
abstract class AppsFlyerService {
  /// Initialize AppsFlyer SDK
  Future<void> initialize();

  /// Start tracking the SDK
  Future<void> startTracking();

  /// Log a custom event
  Future<void> logEvent(String eventName, Map<String, dynamic>? eventValues);

  /// Set user ID for tracking
  Future<void> setCustomerUserId(String userId);

  /// Get AppsFlyer ID
  Future<String?> getAppsFlyerId();

  /// Enable or disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled);

  /// Update server URLs for GDPR compliance
  Future<void> updateServerUnconsentedAtdUserDataUsage();

  /// Stop the SDK
  Future<void> stop(bool shouldStop);
}

@Singleton(as: AppsFlyerService)
class AppsFlyerServiceImpl implements AppsFlyerService {
  AppsFlyerServiceImpl();

  late final AppsflyerSdk _appsflyerSdk;
  bool _isInitialized = false;

  // TODO: Replace these with your actual AppsFlyer credentials
  static const String _devKey = 'YOUR_APPSFLYER_DEV_KEY';
  static const String _appId = 'YOUR_IOS_APP_ID'; // iOS App ID

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.d('AppsFlyer already initialized');
      return;
    }

    try {
      final options = AppsFlyerOptions(
        afDevKey: _devKey,
        appId: _appId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 50, // for iOS 14.5+
        disableAdvertisingIdentifier: false,
        disableCollectASA: false, // iOS App Store tracking
        manualStart: true, // We'll start tracking manually
      );

      _appsflyerSdk = AppsflyerSdk(options);

      // Initialize conversion data listener
      // Using unawaited because initSdk returns a Future but we don't need to wait
      unawaited(
        _appsflyerSdk.initSdk(
          registerConversionDataCallback: true,
          registerOnAppOpenAttributionCallback: true,
          registerOnDeepLinkingCallback: true,
        ),
      );

      // Set up callbacks
      _setupCallbacks();

      _isInitialized = true;
      logger.d('AppsFlyer initialized successfully');
    } catch (e) {
      logger.d('AppsFlyer initialization error: $e');
    }
  }

  @override
  Future<void> startTracking() async {
    if (!_isInitialized) {
      logger.d('AppsFlyer not initialized, cannot start tracking');
      return;
    }

    try {
      _appsflyerSdk.startSDK(
        onSuccess: () {
          logger.d('AppsFlyer SDK started successfully');
        },
      );
    } catch (e) {
      logger.d('AppsFlyer start tracking error: $e');
    }
  }

  @override
  Future<void> logEvent(
    String eventName,
    Map<String, dynamic>? eventValues,
  ) async {
    if (!_isInitialized) {
      logger.d('AppsFlyer not initialized, cannot log event');
      return;
    }

    try {
      // logEvent is fire-and-forget
      unawaited(_appsflyerSdk.logEvent(eventName, eventValues));
      logger.d('AppsFlyer event logged: $eventName');
    } catch (e) {
      logger.d('AppsFlyer logEvent error: $e');
    }
  }

  @override
  Future<void> setCustomerUserId(String userId) async {
    if (!_isInitialized) {
      logger.d('AppsFlyer not initialized, cannot set user ID');
      return;
    }

    try {
      _appsflyerSdk.setCustomerUserId(userId);
      logger.d('AppsFlyer user ID set: $userId');
    } catch (e) {
      logger.d('AppsFlyer setCustomerUserId error: $e');
    }
  }

  @override
  Future<String?> getAppsFlyerId() async {
    if (!_isInitialized) {
      logger.d('AppsFlyer not initialized, cannot get ID');
      return null;
    }

    try {
      return await _appsflyerSdk.getAppsFlyerUID();
    } catch (e) {
      logger.d('AppsFlyer getAppsFlyerId error: $e');
      return null;
    }
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (!_isInitialized) {
      logger.d('AppsFlyer not initialized, cannot set analytics collection');
      return;
    }

    try {
      _appsflyerSdk.stop(!enabled);
      logger.d('AppsFlyer analytics collection enabled: $enabled');
    } catch (e) {
      logger.d('AppsFlyer setAnalyticsCollectionEnabled error: $e');
    }
  }

  @override
  Future<void> updateServerUnconsentedAtdUserDataUsage() async {
    // This method is for GDPR compliance - not available in all SDK versions
    // Keeping as placeholder for future use
    logger.d(
      'AppsFlyer GDPR compliance method not implemented in current SDK version',
    );
  }

  @override
  Future<void> stop(bool shouldStop) async {
    if (!_isInitialized) {
      logger.d('AppsFlyer not initialized, cannot stop');
      return;
    }

    try {
      _appsflyerSdk.stop(shouldStop);
      logger.d('AppsFlyer stopped: $shouldStop');
    } catch (e) {
      logger.d('AppsFlyer stop error: $e');
    }
  }

  /// Set up callbacks for attribution and deep linking
  void _setupCallbacks() {
    // Conversion data callback (install attribution)
    _appsflyerSdk.onInstallConversionData((Map<String, dynamic> data) {
      logger.d('AppsFlyer install conversion data: $data');
      // Handle attribution data here
      // Example: Check if user came from specific campaign
    });

    // App open attribution callback (deep linking)
    _appsflyerSdk.onAppOpenAttribution((Map<String, dynamic> data) {
      logger.d('AppsFlyer app open attribution: $data');
      // Handle deep linking data here
    });

    // Deep linking callback
    _appsflyerSdk.onDeepLinking((DeepLinkResult result) {
      logger.d('AppsFlyer deep linking result: ${result.deepLink}');
      // Handle deep link navigation here
      // Example: Navigate to specific screen based on deep link
    });
  }
}
