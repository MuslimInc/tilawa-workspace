import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/config/currency_config.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../main.dart';
import 'crashlytics_service.dart';

/// Service to initialize analytics with user data and app settings
@Singleton()
class AnalyticsInitializationService {
  AnalyticsInitializationService(
    this._analyticsService,
    this._auth,
    this._crashlyticsService,
  );

  final AnalyticsService _analyticsService;
  final FirebaseAuth _auth;
  final CrashlyticsService _crashlyticsService;

  /// Initialize analytics with user data
  Future<void> initialize() async {
    try {
      // Set user ID if user is logged in
      final User? user = _auth.currentUser;
      if (user != null) {
        await _analyticsService.setUserId(user.uid);
        await _crashlyticsService.setUserId(user.uid);

        // Set user properties
        await _analyticsService.setUserProperty(
          UserProperties.userType,
          UserPropertyValues.authenticated,
        );
        await _analyticsService.setUserProperty(
          UserProperties.signInMethod,
          user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : UserPropertyValues.unknown,
        );

        // Set Crashlytics custom keys
        await _crashlyticsService.setCustomKeys({
          UserProperties.userType: UserPropertyValues.authenticated,
          UserProperties.signInMethod: user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : UserPropertyValues.unknown,
        });
      } else {
        await _analyticsService.setUserId(null);
        await _crashlyticsService.setUserId('');
        await _analyticsService.setUserProperty(
          UserProperties.userType,
          UserPropertyValues.anonymous,
        );
        await _crashlyticsService.setCustomKey(
          UserProperties.userType,
          UserPropertyValues.anonymous,
        );
      }

      // Log app start event
      await _analyticsService.logEvent(
        AnalyticsEvents.appStart,
        parameters: {
          AnalyticsParams.timestamp: DateTime.now().millisecondsSinceEpoch,
          ...CurrencyConfig.getAnalyticsParams(),
        },
      );

      // Set Crashlytics breadcrumb
      await _crashlyticsService.setBreadcrumb('App started');

      logger.d('Analytics initialized successfully');
    } catch (e) {
      logger.d('Analytics initialization error: $e');
    }
  }

  /// Update user properties when user signs in
  Future<void> onUserSignIn() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _analyticsService.setUserId(user.uid);
        await _analyticsService.setUserProperty(
          UserProperties.userType,
          UserPropertyValues.authenticated,
        );
        await _analyticsService.setUserProperty(
          UserProperties.signInMethod,
          user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : UserPropertyValues.unknown,
        );

        await _analyticsService.logLogin(
          loginMethod: user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : UserPropertyValues.unknown,
        );
      }
    } catch (e) {
      logger.d('Analytics sign in error: $e');
    }
  }

  /// Update user properties when user signs out
  Future<void> onUserSignOut() async {
    try {
      await _analyticsService.setUserId(null);
      await _analyticsService.setUserProperty(
        UserProperties.userType,
        UserPropertyValues.anonymous,
      );
      await _analyticsService.setUserProperty(
        UserProperties.signInMethod,
        null,
      );

      await _analyticsService.logEvent(AnalyticsEvents.userSignOut);
    } catch (e) {
      logger.d('Analytics sign out error: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analyticsService.logScreenView(
        screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      logger.d('Analytics screen view error: $e');
    }
  }
}
