import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/currency_config.dart';
import 'package:muzakri/core/services/analytics_service.dart';

/// Service to initialize analytics with user data and app settings
@Singleton()
class AnalyticsInitializationService {
  AnalyticsInitializationService(this._analyticsService, this._auth);

  final AnalyticsService _analyticsService;
  final FirebaseAuth _auth;

  /// Initialize analytics with user data
  Future<void> initialize() async {
    try {
      // Set user ID if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _analyticsService.setUserId(user.uid);

        // Set user properties
        await _analyticsService.setUserProperty('user_type', 'authenticated');
        await _analyticsService.setUserProperty(
          'sign_in_method',
          user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'unknown',
        );
      } else {
        await _analyticsService.setUserId(null);
        await _analyticsService.setUserProperty('user_type', 'anonymous');
      }

      // Log app start event
      await _analyticsService.logEvent(
        'app_start',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...CurrencyConfig.getAnalyticsParams(),
        },
      );

      print('Analytics initialized successfully');
    } catch (e) {
      print('Analytics initialization error: $e');
    }
  }

  /// Update user properties when user signs in
  Future<void> onUserSignIn() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _analyticsService.setUserId(user.uid);
        await _analyticsService.setUserProperty('user_type', 'authenticated');
        await _analyticsService.setUserProperty(
          'sign_in_method',
          user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'unknown',
        );

        await _analyticsService.logLogin(
          loginMethod: user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'unknown',
        );
      }
    } catch (e) {
      print('Analytics sign in error: $e');
    }
  }

  /// Update user properties when user signs out
  Future<void> onUserSignOut() async {
    try {
      await _analyticsService.setUserId(null);
      await _analyticsService.setUserProperty('user_type', 'anonymous');
      await _analyticsService.setUserProperty('sign_in_method', null);

      await _analyticsService.logEvent('user_sign_out');
    } catch (e) {
      print('Analytics sign out error: $e');
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
      print('Analytics screen view error: $e');
    }
  }
}
