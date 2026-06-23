import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/bootstrap/cold_start_navigation_metrics.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/router/app_links_config.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../features/quran_sessions/router/quran_sessions_nav.dart';
import 'app_router_config.dart';
import 'app_navigator_keys.dart';
import 'quran_sessions_session_guard.dart';
import 'shell_route_location.dart';
import 'json_type_registry.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = appRootNavigatorKey;

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

  /// When set before the first [router] access, [GoRouter] uses this location
  /// instead of [SplashRoute] so notification cold start skips the second splash.
  static String? pendingColdStartLocation;

  /// Optional route extra for [pendingColdStartLocation] (e.g. [ReciterEntity]).
  static Object? pendingColdStartExtra;

  /// Non-notification startup destination selected before the router is built.
  static String? _initialLaunchLocation;

  /// The ID of the last local notification that was processed (cold-start or
  /// resume). Used to prevent the resume handler from re-processing the same
  /// launch notification that the splash screen already handled.
  static int? lastProcessedNotificationId;

  static const Duration _notificationNavDedupWindow = Duration(seconds: 3);
  static String? _lastNotificationNavigationSignature;
  static DateTime? _lastNotificationNavigationAt;

  /// Navigate to a notification destination from a cold start.
  ///
  /// Goes to home first, then pushes the target so back returns to home
  /// (same stack shape as [navigateToNotification]).
  static void navigateFromColdStart(String location, {Object? extra}) {
    _navigateToNotificationLocation(location, extra: extra, coldStart: true);
  }

  /// Navigate to a notification destination while the app is already running
  /// (foreground or background tap). Goes to home first, then pushes the target.
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
      clearPendingColdStartRoute();
      final String homeLocation = const HomeRoute().location;

      ColdStartNavigationMetrics.logNavigation(
        phase: coldStart ? 'cold_start_home_push' : 'warm_home_push',
        location: location,
        coldStart: coldStart,
        extra: extra,
      );
      // Always go to home first so Back from any notification target
      // returns to home rather than exiting the app (previously prayer
      // status used a bare go() which replaced the entire back stack).
      router.go(homeLocation);
      if (location != homeLocation) {
        router.push(location, extra: extra);
      }
      ColdStartNavigationMetrics.logMatchedLocation(_currentLocation());
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
    final String? invalidRestoredRoute = _redirectInvalidRestoredPath(state);
    if (invalidRestoredRoute != null) {
      return invalidRestoredRoute;
    }

    final String? sessionGuard = quranSessionsSessionRedirect(context, state);
    if (sessionGuard != null) {
      return sessionGuard;
    }

    // Presentation entry without active media is invalid (playback ≠ URL).
    // Guard with try-catch: during state restoration the BlocProvider ancestor
    // may not yet be mounted when GoRouter evaluates the first redirect.
    if (state.uri.path == '/player') {
      try {
        final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
        if (!bloc.state.hasAudio) {
          if (getIt.isRegistered<AudioPlayerRepository>()) {
            final bool handlerHasSession =
                getIt<AudioPlayerRepository>().readActivePlaybackSnapshot() !=
                null;
            if (handlerHasSession) {
              bloc.add(
                const AudioPlayerEvent.requestPlaybackReconciliation(),
              );
              return null;
            }
          }
          return const HomeRoute().location;
        }
      } catch (_) {
        // BlocProvider not yet in tree — treat as no audio and redirect home.
        return const HomeRoute().location;
      }
    }
    return null;
  }

  /// Sends users home when platform restoration replays a path-param route
  /// without the param GoRouter expects (null-check crash in generated
  /// `_fromState`, Sentry 7549523213).
  static String? _redirectInvalidRestoredPath(GoRouterState state) {
    final List<String> segments = state.uri.pathSegments;
    if (segments.isEmpty) {
      return null;
    }

    if (segments.first == 'reciter' &&
        (segments.length < 2 || segments[1].isEmpty)) {
      return const HomeRoute().location;
    }

    if (segments.first == 'quran-reader' &&
        (segments.length < 2 || segments[1].isEmpty)) {
      return const HomeRoute().location;
    }

    if (segments.length >= 3 &&
        segments[0] == 'sessions' &&
        segments[1] == 'teachers' &&
        segments[2].isEmpty) {
      return const HomeRoute().location;
    }

    if (segments.first == 'athkar' &&
        segments.length >= 2 &&
        segments[1] != 'tasbeeh' &&
        segments[1].isEmpty) {
      return const HomeRoute().location;
    }

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

  /// Location used when constructing [router] for this process.
  @visibleForTesting
  static String resolveInitialLocation() {
    final String? coldStart = pendingColdStartLocation;
    if (coldStart != null && coldStart.isNotEmpty) {
      return const HomeRoute().location;
    }
    final String? initialLaunchLocation = _initialLaunchLocation;
    if (initialLaunchLocation != null && initialLaunchLocation.isNotEmpty) {
      return initialLaunchLocation;
    }
    return AppLinksConfig.defaultColdStartLocation;
  }

  /// Sets the first route used when startup can skip `/splash`.
  static void setInitialLaunchLocation(String location) {
    _initialLaunchLocation = location;
  }

  /// Records a notification cold-start target resolved during bootstrap.
  static void setPendingColdStartRoute(String location, {Object? extra}) {
    _initialLaunchLocation = null;
    pendingColdStartLocation = location;
    pendingColdStartExtra = extra;
    disableStateRestoration = true;
    pendingStartupNotificationLaunch = true;
    ColdStartNavigationMetrics.logResolvedRoute(location, extra: extra);
  }

  static void clearPendingColdStartRoute() {
    pendingColdStartLocation = null;
    pendingColdStartExtra = null;
  }

  static void clearInitialLaunchLocation() {
    _initialLaunchLocation = null;
  }

  /// Clears notification launch flags after cold-start routing is consumed.
  static void consumePendingNotificationLaunchState() {
    pendingFcmMessage = null;
    pendingLocalNotificationResponse = null;
    pendingStartupNotificationLaunch = false;
    disableStateRestoration = false;
    clearPendingColdStartRoute();
  }

  @visibleForTesting
  static void resetForTesting() {
    _router = null;
    disableStateRestoration = false;
    _initialLaunchLocation = null;
    pendingFcmMessage = null;
    pendingLocalNotificationResponse = null;
    pendingStartupNotificationLaunch = false;
    clearPendingColdStartRoute();
    lastProcessedNotificationId = null;
    _lastNotificationNavigationSignature = null;
    _lastNotificationNavigationAt = null;
    isOnPrayerNotificationStatusRouteOverride = null;
  }

  static GoRouter get router {
    if (_router == null) {
      final String initialLocation = resolveInitialLocation();
      if (initialLocation == const SplashRoute().location) {
        ColdStartNavigationMetrics.recordRouterSplash();
      }
      _router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: initialLocation,
        initialExtra: null,
        overridePlatformDefaultLocation:
            !AppLinksConfig.usePlatformDefaultLocation,
        debugLogDiagnostics: kDebugMode,
        // Disable restoration when launched from notification to prevent
        // the restored state from overriding notification navigation
        restorationScopeId: disableStateRestoration
            ? null
            : AppStrings.routerRestorationScopeId,
        redirect: redirect,
        routes: [...$appRoutes, ...quranSessionsRoutes],
        errorBuilder: errorBuilder,
        extraCodec: const AppRouterExtraCodec(),
        observers: _getObservers(),
      );
    }
    return _router!;
  }

  static List<NavigatorObserver> _getObservers() {
    final List<NavigatorObserver> observers = <NavigatorObserver>[];
    try {
      observers.add(
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      );
    } catch (e) {
      // In tests or if Firebase is not initialized, skip analytics observer.
    }
    return observers;
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
      return ShellRouteLocation.activeMatchedLocation();
    } catch (_) {
      return null;
    }
  }

  /// Optional override for unit tests that cannot mount [GoRouter].
  @visibleForTesting
  static bool Function()? isOnPrayerNotificationStatusRouteOverride;

  /// Whether the active route is the prayer notification status screen.
  static bool isOnPrayerNotificationStatusRoute() {
    final bool Function()? override = isOnPrayerNotificationStatusRouteOverride;
    if (override != null) {
      return override();
    }

    final String target = const PrayerNotificationStatusRoute().location;
    try {
      final String activePath =
          router.routerDelegate.currentConfiguration.uri.path;
      if (activePath == target) {
        return true;
      }
      return ShellRouteLocation.matchedLocationStack().contains(target);
    } catch (_) {
      return false;
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
    final Object? decoded = JsonTypeRegistry().decode(input);
    // Belt-and-suspenders: never pass typed wrapper maps to route casts such
    // as `state.extra as ReciterEntity?` (Sentry 7549523148).
    if (decoded is Map && decoded.containsKey('__type')) {
      return null;
    }
    return decoded;
  }
}

class _ExtraEncoder extends Converter<Object?, Object?> {
  const _ExtraEncoder();

  @override
  Object? convert(Object? input) {
    return JsonTypeRegistry().encode(input);
  }
}
