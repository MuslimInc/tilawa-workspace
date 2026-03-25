import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

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

  /// Navigate to a notification destination from a cold start.
  /// Goes to Home first, then pushes the target so back button works.
  static void navigateFromColdStart(String location, {Object? extra}) {
    disableStateRestoration = false;
    pendingStartupNotificationLaunch = false;
    final String homeLocation = const HomeRoute().location;
    router.go(homeLocation);
    if (location != homeLocation) {
      router.push(location, extra: extra);
    }
  }

  /// Navigate to a notification destination while the app is already running
  /// (foreground or background tap). Goes to Home first, then pushes the target.
  static void navigateToNotification(String location, {Object? extra}) {
    final String homeLocation = const HomeRoute().location;
    router.go(homeLocation);
    if (location != homeLocation) {
      router.push(location, extra: extra);
    }
  }

  static String? redirect(BuildContext context, GoRouterState state) {
    // For now, we'll handle auth redirects in the UI
    return null;
  }

  static Widget errorBuilder(BuildContext context, GoRouterState state) =>
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(context.l10n.pageNotFound(state.uri.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => const HomeRoute().go(context),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
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
