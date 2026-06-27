import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/navigation/notification_launch_dedup.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_dispatcher.dart';
import 'package:tilawa/core/services/notification_startup_service.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_constants.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_dedup_snapshot.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_log_store.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Developer-only orchestration for notification routing experiments.
@lazySingleton
class NotificationDebugLabService {
  NotificationDebugLabService(
    this._dispatcher,
    this._prefs,
    this._pidProvider,
    this._navigationService,
    this._logStore,
  );

  final INotificationDispatcher _dispatcher;
  final SharedPreferencesAsync _prefs;
  final ProcessIdProvider _pidProvider;
  final NavigationService _navigationService;
  final NotificationDebugLogStore _logStore;

  static const String _athkarPayloadKey = 'last_handled_notification_payload';
  static const String _athkarTimestampKey =
      'last_handled_notification_timestamp';

  String previewSignature({int? notificationId, String? payload}) {
    return NotificationLaunchDedup.launchSignature(
          notificationId: notificationId,
          payload: payload,
        ) ??
        '(none)';
  }

  Future<void> runAction(NotificationDebugActionSpec spec) async {
    if (!kDebugMode) {
      return;
    }
    _logStore.log(
      'action:start',
      detail: '${spec.key} id=${spec.notificationId} payload=${spec.payload}',
    );
    switch (spec.mechanism) {
      case NotificationDebugMechanism.realLocalNotification:
        if (spec.scheduleDelay != null) {
          await _scheduleLocalNotification(spec);
        } else {
          await _showLocalNotification(spec);
        }
      case NotificationDebugMechanism.dispatcherSimulation:
        await simulateDispatcherTap(spec);
      case NotificationDebugMechanism.bootstrapLaunchProbe:
        await simulateBootstrapLaunchProbe(spec);
      case NotificationDebugMechanism.dedupOnly:
        await markProcessed(spec);
      case NotificationDebugMechanism.clearPidScope:
        await clearPidScope();
    }
    _logStore.log('action:done', detail: spec.key);
  }

  Future<void> _scheduleLocalNotification(
    NotificationDebugActionSpec spec,
  ) async {
    final Duration delay = spec.scheduleDelay ?? const Duration(seconds: 5);
    _logStore.log(
      'notification scheduled',
      detail: 'id=${spec.notificationId} in ${delay.inSeconds}s',
    );
    await Future<void>.delayed(delay);
    await _showLocalNotification(spec);
  }

  Future<void> _showLocalNotification(NotificationDebugActionSpec spec) async {
    await _dispatcher.initialize(createHighImportanceChannel: false);
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'athkar_channel',
          'Debug Lab',
          importance: Importance.high,
          priority: Priority.high,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    await _dispatcher.notificationsPlugin.show(
      id: spec.notificationId ?? NotificationDebugConstants.emptyPayload,
      title: 'Debug Lab',
      body: spec.key,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: spec.payload,
    );
    _logStore.log(
      'notification scheduled',
      detail: 'id=${spec.notificationId} immediate show',
    );
  }

  Future<void> simulateDispatcherTap(NotificationDebugActionSpec spec) async {
    final String? payload = spec.payload;
    final Map<String, dynamic>? data =
        NotificationNavigationResolver.notificationDataFromPayload(payload);
    final String route = data == null
        ? const HomeRoute().location
        : NotificationNavigationResolver.resolveLocation(data);
    _logStore.log('payload parsed', detail: data?.toString() ?? '(null)');
    _logStore.log('route resolved', detail: route);
    _logStore.log(
      'dedup signature',
      detail: previewSignature(
        notificationId: spec.notificationId,
        payload: payload,
      ),
    );

    final NotificationResponse response = NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      id: spec.notificationId,
      payload: payload,
    );

    final INotificationDispatcher dispatcher = _dispatcher;
    if (dispatcher is NotificationDispatcher) {
      // ignore: invalid_use_of_visible_for_testing_member
      final bool handled = await dispatcher.routeNotificationForTest(response);
      _logStore.log(
        handled ? 'navigation success' : 'navigation skipped',
        detail: 'NotificationDispatcher.routeNotificationForTest',
      );
      if (!handled && data != null) {
        _navigationService.navigateToNotification(route);
        _logStore.log('navigation fallback', detail: route);
      }
      return;
    }

    if (data != null) {
      _navigationService.navigateToNotification(route);
      _logStore.log('navigation fallback', detail: route);
    }
  }

  Future<void> simulateBootstrapLaunchProbe(
    NotificationDebugActionSpec spec,
  ) async {
    final bool processed = await AppRouter.isProcessedNotificationLaunch(
      launchNotificationId: spec.notificationId,
      launchPayload: spec.payload,
    );
    if (processed) {
      _logStore.log('dedup skipped replay', detail: spec.key);
      return;
    }

    final NotificationResponse response = NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      id: spec.notificationId,
      payload: spec.payload,
    );
    AppRouter.pendingLocalNotificationResponse = response;
    AppRouter.lastProcessedNotificationId = spec.notificationId;
    await AppRouter.persistProcessedNotificationLaunch(
      notificationId: spec.notificationId,
      payload: spec.payload,
    );
    _logStore.log('dedup persisted');

    final AppStartupTasks tasks = AppStartupTasks(
      launchConfig: const AppLaunchConfig(notificationLaunchProbe: true),
    );
    // ignore: invalid_use_of_visible_for_testing_member
    tasks.applyColdStartRouteFromPendingLaunchForTesting();
    _logStore.log(
      'pending route set',
      detail: AppRouter.pendingColdStartLocation ?? '(none)',
    );

    if (AppRouter.pendingColdStartLocation != null) {
      _navigationService.navigateToNotification(
        AppRouter.pendingColdStartLocation!,
        extra: AppRouter.pendingColdStartExtra,
      );
      AppRouter.consumePendingNotificationLaunchState();
      _logStore.log('pending route consumed');
    }
  }

  Future<void> markProcessed(NotificationDebugActionSpec spec) async {
    await AppRouter.persistProcessedNotificationLaunch(
      notificationId: spec.notificationId,
      payload: spec.payload,
    );
    _logStore.log(
      'dedup persisted',
      detail: previewSignature(
        notificationId: spec.notificationId,
        payload: spec.payload,
      ),
    );
  }

  Future<void> clearPidScope() async {
    await _prefs.remove(NotificationLaunchDedup.lastNotifPidKey);
    _logStore.log('pid scope cleared', detail: 'simulate fresh process dedup');
  }

  Future<NotificationDebugDedupSnapshot> readSnapshot({
    int? previewNotificationId,
    String? previewPayload,
  }) async {
    final int pid = _pidProvider.currentPid;
    final int? storedPid = await _prefs.getInt(
      NotificationLaunchDedup.lastNotifPidKey,
    );
    final int? storedId =
        await NotificationLaunchDedup.readStoredNotificationId(
          prefs: _prefs,
          pid: pid,
        );
    final String? storedSig = await NotificationLaunchDedup.readStoredSignature(
      prefs: _prefs,
      pid: pid,
    );
    final String? previewSig =
        previewNotificationId != null ||
            (previewPayload != null && previewPayload.isNotEmpty)
        ? previewSignature(
            notificationId: previewNotificationId,
            payload: previewPayload,
          )
        : null;
    final bool? processedPreview = previewSig == null
        ? null
        : await AppRouter.isProcessedNotificationLaunch(
            launchNotificationId: previewNotificationId,
            launchPayload: previewPayload,
          );

    return NotificationDebugDedupSnapshot(
      currentPid: pid,
      storedPid: storedPid,
      storedNotificationId: storedId,
      storedPayloadSignature: storedSig,
      lastProcessedNotificationId: AppRouter.lastProcessedNotificationId,
      pendingColdStartLocation: AppRouter.pendingColdStartLocation,
      pendingColdStartExtra: AppRouter.pendingColdStartExtra,
      athkarLastHandledPayload: await _prefs.getString(_athkarPayloadKey),
      athkarLastHandledTimestampMs: await _prefs.getInt(_athkarTimestampKey),
      incomingSignaturePreview: previewSig,
      isProcessedPreview: processedPreview,
    );
  }

  Future<void> clearDedupState() async {
    await _prefs.remove(NotificationLaunchDedup.lastNotifIdKey);
    await _prefs.remove(NotificationLaunchDedup.lastNotifPidKey);
    await _prefs.remove(NotificationLaunchDedup.lastNotifPayloadSigKey);
    AppRouter.clearInMemoryNotificationLaunchStateForDebug();
    _logStore.log('dedup cleared');
  }

  Future<void> clearAthkarDedupState() async {
    await _prefs.remove(_athkarPayloadKey);
    await _prefs.remove(_athkarTimestampKey);
    _logStore.log('athkar dedup cleared');
  }

  Future<void> clearAllDebugState() async {
    await clearDedupState();
    await clearAthkarDedupState();
    _logStore.clear();
  }
}
