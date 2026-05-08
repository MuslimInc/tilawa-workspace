import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'app_router_config.dart';
import 'json_type_registry.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Flag to disable state restoration when launched from notification
  /// This is set before the router is created and prevents restoration
  /// from overriding the notification navigation.
  static bool disableStateRestoration = false;

  /// Holds the FCM initial message consumed during bootstrap.
  /// [getInitialMessage] can only be called once, so we capture it early
  /// and let the splash use case read it from here.
  static RemoteMessage? pendingFcmMessage;

  /// Holds the cold-start local notification response captured during
  /// bootstrap so splash does not need another platform call.
  static NotificationResponse? pendingLocalNotificationResponse;

  /// Indicates that the app cold-started from a notification and splash
  /// should be the only place that consumes that startup navigation.
  static bool pendingStartupNotificationLaunch = false;

  /// The ID of the last local notification that was processed (cold-start or
  /// resume). Used to prevent the resume handler from re-processing the same
  /// launch notification that the splash screen already handled.
  static int? lastProcessedNotificationId;

  static const Duration _notificationNavDedupWindow = Duration(seconds: 3);
  static String? _lastNotificationNavigationSignature;
  static DateTime? _lastNotificationNavigationAt;

  /// Navigate to a notification destination from a cold start.
  /// Goes to Home first, then pushes the target so back button works.
  static void navigateFromColdStart(String location, {Object? extra}) {
    _navigateToNotificationLocation(location, extra: extra, coldStart: true);
  }

  /// Navigate to a notification destination while the app is already running
  /// (foreground or background tap). Goes to Home first, then pushes the target.
  static void navigateToNotification(String location, {Object? extra}) {
    _navigateToNotificationLocation(location, extra: extra, coldStart: false);
  }

  static void _navigateToNotificationLocation(
    String location, {
    Object? extra,
    required bool coldStart,
  }) {
    final bool isPrayerStatus =
        location == const PrayerNotificationStatusRoute().location;
    if (isPrayerStatus) {
      logger.d(
        '[AppRouter] NAVIGATION_TO_PRAYER_STATUS_REQUESTED coldStart=$coldStart routerReady=${navigatorKey.currentContext != null}',
      );
    }

    try {
      if (_isDuplicateNotificationNavigation(location, extra)) {
        logger.d('[AppRouter] Duplicate notification navigation ignored');
        return;
      }

      final String? currentLocation = _currentLocation();
      if (_isSameTargetNavigation(
        currentLocation: currentLocation,
        targetLocation: location,
      )) {
        logger.d(
          '[AppRouter] Notification navigation skipped (already on target): $location',
        );
        return;
      }

      disableStateRestoration = false;
      pendingStartupNotificationLaunch = false;
      final String homeLocation = const HomeRoute().location;
      if (isPrayerStatus) {
        // Foreground native Adhan taps can arrive while the app is actively
        // rendering another page. Navigate directly to the status route to
        // avoid transitional home->push races and to refresh extra payload
        // safely when already on status.
        router.go(location, extra: extra);
      } else {
        router.go(homeLocation);
        if (location != homeLocation) {
          router.push(location, extra: extra);
        }
      }
      if (isPrayerStatus) {
        logger.d('[AppRouter] NAVIGATION_TO_PRAYER_STATUS_SUCCESS');
      }
    } catch (e, stackTrace) {
      if (isPrayerStatus) {
        logger.e(
          '[AppRouter] NAVIGATION_TO_PRAYER_STATUS_FAILED: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  static String? redirect(BuildContext context, GoRouterState state) {
    // For now, we'll handle auth redirects in the UI
    return null;
  }

  static Widget errorBuilder(BuildContext context, GoRouterState state) =>
      Scaffold(
        body: TilawaErrorState(
          icon: Icons.error_outline_rounded,
          title: context.l10n.pageNotFound(state.uri.toString()),
          retryLabel: context.l10n.goHome,
          onRetry: () => const HomeRoute().go(context),
        ),
      );

  static GoRouter? _router;

  static GoRouter get router {
    _router ??= GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: const SplashRoute().location,
      overridePlatformDefaultLocation: true,
      debugLogDiagnostics: kDebugMode,
      // Disable restoration when launched from notification to prevent
      // the restored state from overriding notification navigation
      restorationScopeId: disableStateRestoration
          ? null
          : AppStrings.routerRestorationScopeId,
      redirect: redirect,
      routes: $appRoutes,
      errorBuilder: errorBuilder,
      extraCodec: const AppRouterExtraCodec(),
      observers: _getObservers(),
    );
    return _router!;
  }

  static List<NavigatorObserver> _getObservers() {
    try {
      return [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)];
    } catch (e) {
      // In tests or if Firebase is not initialized, return an empty list
      return [];
    }
  }

  static bool _isDuplicateNotificationNavigation(
    String location,
    Object? extra,
  ) {
    final DateTime now = DateTime.now();
    final String signature = '$location|${_notificationExtraSignature(extra)}';

    if (_lastNotificationNavigationSignature == signature &&
        _lastNotificationNavigationAt != null &&
        now.difference(_lastNotificationNavigationAt!) <=
            _notificationNavDedupWindow) {
      return true;
    }

    _lastNotificationNavigationSignature = signature;
    _lastNotificationNavigationAt = now;
    return false;
  }

  static String _notificationExtraSignature(Object? extra) {
    final Object? encoded = JsonTypeRegistry().encode(extra);
    final Object? canonical = _canonicalizeSignatureValue(encoded);
    try {
      return jsonEncode(canonical);
    } catch (_) {
      return canonical?.toString() ?? 'null';
    }
  }

  static Object? _canonicalizeSignatureValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is Map) {
      final List<MapEntry<String, Object?>> entries =
          value.entries
              .map(
                (MapEntry<dynamic, dynamic> e) => MapEntry(
                  e.key.toString(),
                  _canonicalizeSignatureValue(e.value),
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => a.key.compareTo(b.key));

      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value,
      };
    }

    if (value is Iterable) {
      return value.map(_canonicalizeSignatureValue).toList(growable: false);
    }

    return value.toString();
  }

  static String? _currentLocation() {
    try {
      final List<RouteMatchBase> matches =
          router.routerDelegate.currentConfiguration.matches;
      if (matches.isEmpty) return null;
      return matches.last.matchedLocation;
    } catch (_) {
      return null;
    }
  }

  static bool _isSameTargetNavigation({
    required String? currentLocation,
    required String targetLocation,
  }) {
    if (currentLocation == null || currentLocation.isEmpty) {
      return false;
    }

    final String targetPath = Uri.parse(targetLocation).path;

    // For prayer status, we always want to allow re-navigation if it's not a
    // duplicate tap (handled by the outer signature check), because the
    // payload might be different (different prayer time).
    if (targetPath == const PrayerNotificationStatusRoute().location) {
      return false;
    }

    return currentLocation == targetLocation;
  }

  static void init() {
    JsonTypeRegistry().register('ReciterEntity', ReciterEntity.fromJson);
  }
}

@visibleForTesting
class AppRouterExtraCodec extends Codec<Object?, Object?> {
  const AppRouterExtraCodec();

  @override
  Converter<Object?, Object?> get decoder => const _ExtraDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _ExtraEncoder();
}

class _ExtraDecoder extends Converter<Object?, Object?> {
  const _ExtraDecoder();

  @override
  Object? convert(Object? input) {
    return JsonTypeRegistry().decode(input);
  }
}

class _ExtraEncoder extends Converter<Object?, Object?> {
  const _ExtraEncoder();

  @override
  Object? convert(Object? input) {
    return JsonTypeRegistry().encode(input);
  }
}
