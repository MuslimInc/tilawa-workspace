import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import '../../router/app_router.dart';
import '../../router/app_router_config.dart';
import '../bootstrap/app_startup.dart';
import '../logging/app_logger.dart';
import '../navigation/notification_launch_dedup.dart';

typedef NotificationNavigator = void Function(String location, {Object? extra});

// ---------------------------------------------------------------------------
// Minimal injectable wrappers for platform-level dependencies
// ---------------------------------------------------------------------------

/// Provides the current OS process ID.
/// Wraps [dart:io.pid] to allow constructor injection and unit testing.
@lazySingleton
class ProcessIdProvider {
  const ProcessIdProvider();

  int get currentPid => pid;
}

/// Wraps [initializeNotificationHandlers] for constructor injection.
/// Calling this registers all notification handlers (download, athkar, prayer)
/// and is idempotent — [AppStartupTasks] memoises the underlying future.
@lazySingleton
class NotificationHandlersInitializer {
  const NotificationHandlersInitializer();

  Future<void> call() => initializeNotificationHandlers();
}

// ---------------------------------------------------------------------------
// Service interface
// ---------------------------------------------------------------------------

/// Handles notification startup and resume routing for the app.
///
/// Owns:
/// - the 900 ms deferred cold-start probe timer
/// - the PID-based hot-restart dedup guard
/// - SharedPreferences persistence of the last processed notification ID
/// - notification dispatcher initialisation
///
/// [_TilawaAppState] is responsible only for lifecycle callbacks — it
/// delegates all notification handling to this service.
abstract interface class NotificationStartupService {
  /// Call once after the first frame on app startup.
  ///
  /// If a startup notification is pending (FCM path), processes it immediately.
  /// Otherwise schedules the 900 ms deferred probe for local-notification
  /// cold-start detection.
  Future<void> handleAppStartup();

  /// Call on every [AppLifecycleState.resumed] event (after debounce).
  ///
  /// Checks whether the Android Intent notification has already been
  /// processed and skips if it has.
  Future<void> handleAppResume();

  /// Cancel internal timers. Must be called from the widget's [dispose].
  void dispose();
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

@LazySingleton(as: NotificationStartupService)
class NotificationStartupServiceImpl implements NotificationStartupService {
  NotificationStartupServiceImpl(
    this._dispatcher,
    this._prefs,
    this._pidProvider,
    this._handlersInitializer,
    this._adhanPlayer, {
    @visibleForTesting @ignoreParam NotificationNavigator? navigator,
  }) : _navigator = navigator ?? AppRouter.navigateToNotification;

  final INotificationDispatcher _dispatcher;
  final SharedPreferencesAsync _prefs;
  final ProcessIdProvider _pidProvider;
  final NotificationHandlersInitializer _handlersInitializer;
  final IAdhanAlarmPlayer _adhanPlayer;
  final NotificationNavigator _navigator;

  static const Duration _deferredColdStartProbeDelay = Duration(
    milliseconds: 900,
  );

  bool _hasProcessedStartup = false;
  bool _hasPrimedDispatcher = false;
  // Separate flags so the one-shot cold-start probe and the repeating resume
  // handler never mask each other when they race (e.g. slow device startup).
  bool _isColdStartChecking = false;
  bool _isResumeChecking = false;
  Timer? _localLaunchProbeTimer;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  @override
  Future<void> handleAppStartup() async {
    if (_hasProcessedStartup) {
      return;
    }
    _hasProcessedStartup = true;

    // Large-scale startup pattern: avoid eager heavy notification wiring on
    // every cold start. Only process immediately when startup was actually
    // notification-driven (FCM path sets this flag during bootstrap).
    if (AppRouter.pendingStartupNotificationLaunch ||
        AppRouter.pendingColdStartLocation != null) {
      await _handlersInitializer();
      AppRouter.pendingStartupNotificationLaunch = false;
      return;
    }

    // Register tap handlers on every normal launch so foreground notification
    // taps route immediately without requiring a background/resume cycle.
    unawaited(_handlersInitializer());

    // Probe local-notification cold-start lazily so startup frames stay fast.
    // The timer is cancelled in dispose() if the widget unmounts first.
    _localLaunchProbeTimer?.cancel();
    _localLaunchProbeTimer = Timer(_deferredColdStartProbeDelay, () {
      unawaited(_checkForDeferredColdStart());
    });

    if (!_shouldDeferAdhanStatusProbe()) {
      Timer(_deferredColdStartProbeDelay, () {
        unawaited(_routeToStatusIfAdhanPlaying());
      });
    }
  }

  bool _shouldDeferAdhanStatusProbe() {
    return AppRouter.pendingStartupNotificationLaunch ||
        AppRouter.pendingColdStartLocation != null;
  }

  @override
  Future<void> handleAppResume() async {
    if (_isResumeChecking) {
      logger.d(
        '[NotificationStartupService] handleAppResume: skipped – already checking',
      );
      return;
    }
    _isResumeChecking = true;
    logger.d(
      '[NotificationStartupService] handleAppResume: started, lastProcessedId=${AppRouter.lastProcessedNotificationId}',
    );

    try {
      // Ensure handlers are registered before querying launch details.
      await _handlersInitializer();

      // Auto-route to the status screen if an adhan is currently playing.
      // This is the primary path for "user swiped the foreground notification
      // away while adhan kept playing, then re-opened the app". Run before
      // the launch-details check so it isn't suppressed by lastProcessedId.
      await _routeToStatusIfAdhanPlaying();

      // getNotificationAppLaunchDetails() returns the SAME Android-Intent data
      // on every call, so we guard with lastProcessedNotificationId.
      final launchDetails = await _dispatcher.getNotificationAppLaunchDetails();
      final int? currentId = launchDetails?.notificationResponse?.id;
      logger.d(
        '[NotificationStartupService] handleAppResume: currentId=$currentId didLaunch=${launchDetails?.didNotificationLaunchApp}',
      );
      if (currentId == null ||
          currentId == AppRouter.lastProcessedNotificationId) {
        logger.d(
          '[NotificationStartupService] handleAppResume: skipped – same id or null',
        );
        return;
      }

      logger.d(
        '[NotificationStartupService] handleAppResume: processing notification id=$currentId',
      );
      final bool processed = await _dispatcher.processLaunchNotification();
      if (processed) {
        AppRouter.lastProcessedNotificationId = currentId;
        await AppRouter.persistProcessedNotificationLaunch(
          notificationId: currentId,
          payload: launchDetails?.notificationResponse?.payload,
        );
        logger.d(
          '[NotificationStartupService] Launch notification processed on resume',
        );
      }
    } catch (e) {
      logger.d('[NotificationStartupService] Error on resume: $e');
    } finally {
      _isResumeChecking = false;
    }
  }

  @override
  void dispose() {
    _localLaunchProbeTimer?.cancel();
    _localLaunchProbeTimer = null;
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  /// Pulls the currently-playing adhan payload (if any) from the native
  /// service and routes to [PrayerNotificationStatusRoute]. No-op if the
  /// adhan is not playing or the user is already on the status screen.
  Future<void> _routeToStatusIfAdhanPlaying() async {
    try {
      if (_shouldDeferAdhanStatusProbe()) {
        return;
      }
      if (AppRouter.isOnPrayerNotificationStatusRoute()) {
        logger.d(
          '[NotificationStartupService] _routeToStatusIfAdhanPlaying: '
          'skipped – already on status screen',
        );
        return;
      }
      if (!_adhanPlayer.isSupported) return;
      final bool playing = await _adhanPlayer.isAdhanPlaying();
      if (!playing) return;

      final String? payload = await _adhanPlayer.getActiveAdhanPayload();
      if (payload == null || payload.isEmpty) {
        logger.d(
          '[NotificationStartupService] _routeToStatusIfAdhanPlaying: adhan playing but no payload',
        );
        return;
      }

      logger.d(
        '[NotificationStartupService] _routeToStatusIfAdhanPlaying: routing to status screen',
      );
      _navigator(
        const PrayerNotificationStatusRoute().location,
        extra: payload,
      );
    } catch (e) {
      logger.d(
        '[NotificationStartupService] _routeToStatusIfAdhanPlaying failed: $e',
      );
    }
  }

  Future<void> _checkForDeferredColdStart() async {
    if (_isColdStartChecking) {
      logger.d(
        '[NotificationStartupService] _checkForDeferredColdStart: skipped – already checking',
      );
      return;
    }
    _isColdStartChecking = true;
    logger.d(
      '[NotificationStartupService] _checkForDeferredColdStart: started, lastProcessedId=${AppRouter.lastProcessedNotificationId}',
    );

    try {
      // Prime the dispatcher (lightweight channel-only init) so
      // getNotificationAppLaunchDetails() works. Full handler registration
      // is deferred until we confirm there is actually a notification.
      if (!_hasPrimedDispatcher) {
        await _dispatcher.initialize(createHighImportanceChannel: false);
        _hasPrimedDispatcher = true;
      }

      // Restore lastProcessedNotificationId from persistent storage to handle
      // Dart VM restarts (hot restart) where static fields are cleared but the
      // Android Activity's Intent—and therefore getNotificationAppLaunchDetails()
      // —still returns the previously-processed notification.
      if (AppRouter.lastProcessedNotificationId == null) {
        final int? storedId =
            await NotificationLaunchDedup.readStoredNotificationId(
              prefs: _prefs,
              pid: _pidProvider.currentPid,
            );
        final int? storedPid = await _prefs.getInt(
          NotificationLaunchDedup.lastNotifPidKey,
        );
        final int currentPid = _pidProvider.currentPid;
        logger.d(
          '[NotificationStartupService] _checkForDeferredColdStart: prefs storedId=$storedId storedPid=$storedPid currentPid=$currentPid',
        );
        if (storedId != null && storedPid == currentPid) {
          AppRouter.lastProcessedNotificationId = storedId;
          logger.d(
            '[NotificationStartupService] _checkForDeferredColdStart: restored lastProcessedId=$storedId (hot restart)',
          );
        }
      }

      final launchDetails = await _dispatcher.getNotificationAppLaunchDetails();
      final bool didLaunch = launchDetails?.didNotificationLaunchApp ?? false;
      final int? currentId = launchDetails?.notificationResponse?.id;
      logger.d(
        '[NotificationStartupService] _checkForDeferredColdStart: didLaunch=$didLaunch currentId=$currentId lastProcessedId=${AppRouter.lastProcessedNotificationId}',
      );

      if (!didLaunch ||
          currentId == null ||
          currentId == AppRouter.lastProcessedNotificationId) {
        logger.d(
          '[NotificationStartupService] _checkForDeferredColdStart: skipped – didLaunch=$didLaunch currentId=$currentId lastProcessedId=${AppRouter.lastProcessedNotificationId}',
        );
        return;
      }

      logger.d(
        '[NotificationStartupService] _checkForDeferredColdStart: processing notification id=$currentId',
      );
      await _handlersInitializer();
      final bool processed = await _dispatcher.processLaunchNotification();
      if (processed) {
        AppRouter.lastProcessedNotificationId = currentId;
        await AppRouter.persistProcessedNotificationLaunch(
          notificationId: currentId,
          payload: launchDetails?.notificationResponse?.payload,
        );
        logger.d(
          '[NotificationStartupService] Deferred cold-start local notification processed',
        );
      }
    } catch (e) {
      logger.d(
        '[NotificationStartupService] Error processing deferred cold-start notification: $e',
      );
    } finally {
      _isColdStartChecking = false;
    }
  }
}
