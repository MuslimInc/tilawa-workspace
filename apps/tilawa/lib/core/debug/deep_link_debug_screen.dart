import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/bootstrap/cold_start_navigation_metrics.dart';
import 'package:tilawa/core/debug/deep_link_debug_log.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/notification_navigation_resolver.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// In-app panel to exercise notification / deep-link routing scenarios.
///
/// Open from Settings → Developer → Deep link debug (`kDebugMode` only).
class DeepLinkDebugScreen extends StatelessWidget {
  const DeepLinkDebugScreen({super.key});

  static const ReciterEntity _sampleReciter = ReciterEntity(
    id: 7,
    name: 'Debug Reciter',
    letter: 'D',
    date: '2024-01-01',
    moshaf: [],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const TilawaBackButton() : null,
        title: const Text('Deep link debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Filter logs: [DeepLink]\n'
            'Cold-start tests: force-quit app, tap notification or relaunch.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Warm navigation (app running)',
            children: <_DebugAction>[
              _DebugAction(
                label: 'Reciter (id only)',
                subtitle: 'navigateToNotification → home + push',
                onTap: () => _warmReciter(withExtra: false),
              ),
              _DebugAction(
                label: 'Reciter (with \$extra entity)',
                subtitle: 'Skips ReciterDetailsLoader',
                onTap: () => _warmReciter(withExtra: true),
              ),
              _DebugAction(
                label: 'Adhan / prayer status',
                onTap: _warmAdhan,
              ),
              _DebugAction(
                label: 'Home',
                onTap: () => _warmPayload(const {'type': 'home'}),
              ),
              _DebugAction(
                label: 'Settings',
                onTap: () => _warmPayload(const {'type': 'settings'}),
              ),
              _DebugAction(
                label: 'Athkar category',
                onTap: () => _warmPayload(const {
                  'type': 'athkar',
                  'categoryId': '1',
                  'categoryName': 'Morning',
                }),
              ),
              _DebugAction(
                label: 'Quran surah 2',
                onTap: () => _warmPayload(const {
                  'type': 'quran',
                  'surahNumber': '2',
                }),
              ),
            ],
          ),
          _section(
            context,
            title: 'Cold navigation (simulate in-process)',
            children: <_DebugAction>[
              _DebugAction(
                label: 'Cold → reciter',
                subtitle: 'navigateFromColdStart home → push',
                onTap: () => _coldReciter(withExtra: false),
              ),
              _DebugAction(
                label: 'Cold → reciter + \$extra',
                onTap: () => _coldReciter(withExtra: true),
              ),
              _DebugAction(
                label: 'Cold → adhan status',
                onTap: _coldAdhan,
              ),
              _DebugAction(
                label: 'Cold → download-style payload',
                subtitle: 'type=reciter, reciterId only',
                onTap: _coldDownloadPayload,
              ),
            ],
          ),
          _section(
            context,
            title: 'Bootstrap state (kill app after arming)',
            children: <_DebugAction>[
              _DebugAction(
                label: 'Arm FCM reciter cold start',
                subtitle: 'Sets pendingFcm + cold start route',
                onTap: _armFcmReciterColdStart,
              ),
              _DebugAction(
                label: 'Arm local notification cold start',
                subtitle: 'Sets pendingLocal + cold start route',
                onTap: _armLocalReciterColdStart,
              ),
              _DebugAction(
                label: 'Reset launch / router state',
                onTap: _resetLaunchState,
              ),
            ],
          ),
          _section(
            context,
            title: 'Post local notification (tap after kill)',
            children: <_DebugAction>[
              _DebugAction(
                label: 'Show download-complete notification',
                subtitle: 'Tap after force-quit to test bootstrap probe',
                onTap: _showDownloadNotification,
              ),
              _DebugAction(
                label: 'Show generic reciter notification',
                onTap: _showReciterNotification,
              ),
            ],
          ),
          _section(
            context,
            title: 'Diagnostics',
            children: <_DebugAction>[
              _DebugAction(
                label: 'Log current router state',
                onTap: _logRouterState,
              ),
              _DebugAction(
                label: 'Log pending launch flags',
                onTap: _logPendingFlags,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<_DebugAction> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children.map(
          (action) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(action.label),
              subtitle: action.subtitle == null ? null : Text(action.subtitle!),
              trailing: const Icon(Icons.play_arrow),
              onTap: action.onTap,
            ),
          ),
        ),
      ],
    );
  }

  static void _warmReciter({required bool withExtra}) {
    DeepLinkDebugLog.log(
      'warm_reciter tap',
      scenario: 'warm_reciter',
      data: <String, Object?>{'withExtra': withExtra},
    );
    final Map<String, dynamic> data = <String, dynamic>{
      'type': 'reciter',
      'data': '7',
    };
    if (withExtra) {
      data['reciter'] = _sampleReciter.toJson();
    }
    _navigateWarm(data);
  }

  static void _coldReciter({required bool withExtra}) {
    DeepLinkDebugLog.log(
      'cold_reciter tap',
      scenario: 'cold_reciter',
      data: <String, Object?>{'withExtra': withExtra},
    );
    final Map<String, dynamic> data = <String, dynamic>{
      'type': 'reciter',
      'data': '7',
    };
    if (withExtra) {
      data['reciter'] = _sampleReciter.toJson();
    }
    _navigateCold(data);
  }

  static void _warmAdhan() {
    const String payload = '{"prayer_name":"fajr","prayer_id":"1"}';
    DeepLinkDebugLog.log('warm_adhan tap', scenario: 'warm_adhan');
    AppRouter.navigateToNotification(
      const PrayerNotificationStatusRoute().location,
      extra: payload,
    );
    _logRouterState();
  }

  static void _coldAdhan() {
    const String payload = '{"prayer_name":"asr","prayer_id":"3"}';
    DeepLinkDebugLog.log('cold_adhan tap', scenario: 'cold_adhan');
    AppRouter.navigateFromColdStart(
      const PrayerNotificationStatusRoute().location,
      extra: payload,
    );
    _logRouterState();
  }

  static void _coldDownloadPayload() {
    DeepLinkDebugLog.log(
      'cold_download tap',
      scenario: 'cold_download',
    );
    _navigateCold(const {
      'type': 'reciter',
      'reciterId': 7,
      'reciterName': 'Debug Reciter',
    });
  }

  static void _warmPayload(Map<String, dynamic> data) {
    DeepLinkDebugLog.log(
      'warm_payload tap',
      scenario: 'warm_payload',
      data: data,
    );
    _navigateWarm(data);
  }

  static void _navigateWarm(Map<String, dynamic> data) {
    final String location = NotificationNavigationResolver.resolveLocation(
      data,
    );
    final Object? extra = NotificationNavigationResolver.resolveExtra(
      data,
      location,
    );
    DeepLinkDebugLog.log(
      'navigateToNotification',
      scenario: 'warm_nav',
      data: <String, Object?>{
        'location': location,
        'hasExtra': extra != null,
      },
    );
    AppRouter.navigateToNotification(location, extra: extra);
    _logRouterState();
  }

  static void _navigateCold(Map<String, dynamic> data) {
    final String location = NotificationNavigationResolver.resolveLocation(
      data,
    );
    final Object? extra = NotificationNavigationResolver.resolveExtra(
      data,
      location,
    );
    AppRouter.navigateFromColdStart(location, extra: extra);
    _logRouterState();
  }

  static void _armFcmReciterColdStart() {
    DeepLinkDebugLog.log(
      'arm_fcm_cold_start',
      scenario: 'arm_fcm',
    );
    AppRouter.pendingFcmMessage = RemoteMessage(
      data: const <String, String>{
        'type': 'reciter',
        'data': '7',
      },
    );
    AppRouter.setPendingColdStartRoute(
      const ReciterDetailsRoute(reciterId: '7').location,
    );
    _logPendingFlags();
    DeepLinkDebugLog.log(
      'ARMED — force-quit and relaunch; check bootstrap logs',
      scenario: 'arm_fcm',
    );
  }

  static void _armLocalReciterColdStart() {
    DeepLinkDebugLog.log(
      'arm_local_cold_start',
      scenario: 'arm_local',
    );
    AppRouter.pendingLocalNotificationResponse = const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: '{"type":"reciter","data":"7","reciterId":7}',
    );
    AppRouter.setPendingColdStartRoute(
      const ReciterDetailsRoute(reciterId: '7').location,
    );
    AppRouter.lastProcessedNotificationId = 999001;
    _logPendingFlags();
    DeepLinkDebugLog.log(
      'ARMED — force-quit and relaunch',
      scenario: 'arm_local',
    );
  }

  static void _resetLaunchState() {
    DeepLinkDebugLog.log('reset_launch_state', scenario: 'reset');
    AppStartupTasks().resetLaunchState();
    AppRouter.pendingFcmMessage = null;
    AppRouter.pendingLocalNotificationResponse = null;
    AppRouter.pendingStartupNotificationLaunch = false;
    AppRouter.clearPendingColdStartRoute();
    AppRouter.disableStateRestoration = false;
    AppRouter.lastProcessedNotificationId = null;
    AppRouter.init();
    _logPendingFlags();
  }

  static Future<void> _showDownloadNotification() async {
    await DeepLinkDebugLog.timeAsync(
      'show_download_notification',
      () async {
        final INotificationDispatcher dispatcher =
            getIt<INotificationDispatcher>();
        await dispatcher.initialize(createHighImportanceChannel: true);
        final String payload = jsonEncode(<String, Object>{
          'type': 'reciter',
          'data': '7',
          'reciterId': 7,
          'reciterName': 'Debug Reciter',
        });
        await dispatcher.notificationsPlugin.show(
          id: 999002,
          title: '[DeepLink] Download complete',
          body: 'Tap to open reciter 7 (cold start test)',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
        );
        DeepLinkDebugLog.log(
          'notification shown id=999002',
          scenario: 'local_notif',
          data: <String, Object?>{'payload': payload},
        );
      },
      scenario: 'show_download',
    );
  }

  static Future<void> _showReciterNotification() async {
    await DeepLinkDebugLog.timeAsync(
      'show_reciter_notification',
      () async {
        final INotificationDispatcher dispatcher =
            getIt<INotificationDispatcher>();
        await dispatcher.initialize(createHighImportanceChannel: true);
        final String payload = jsonEncode({
          'type': 'reciter',
          'data': '7',
          'reciter': _sampleReciter.toJson(),
        });
        await dispatcher.notificationsPlugin.show(
          id: 999003,
          title: '[DeepLink] Reciter',
          body: 'Tap — includes reciter JSON extra',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
        );
      },
      scenario: 'show_reciter',
    );
  }

  static void _logRouterState() {
    try {
      final String loc = AppRouter
          .router
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
      DeepLinkDebugLog.log(
        'router_state',
        scenario: 'diag',
        data: <String, Object?>{'uri': loc},
      );
    } catch (e) {
      DeepLinkDebugLog.log(
        'router_state_error',
        scenario: 'diag',
        data: <String, Object?>{'error': e.toString()},
      );
    }
  }

  static void _logPendingFlags() {
    DeepLinkDebugLog.log(
      'pending_flags',
      scenario: 'diag',
      data: <String, Object?>{
        'pendingFcm': AppRouter.pendingFcmMessage != null,
        'pendingLocal': AppRouter.pendingLocalNotificationResponse != null,
        'pendingStartupNotificationLaunch':
            AppRouter.pendingStartupNotificationLaunch,
        'pendingColdStartLocation': AppRouter.pendingColdStartLocation,
        'pendingColdStartExtra': AppRouter.pendingColdStartExtra != null,
        'disableStateRestoration': AppRouter.disableStateRestoration,
        'splashScreenCount': ColdStartNavigationMetrics.splashScreenCount,
      },
    );
  }
}

class _DebugAction {
  const _DebugAction({
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;
}
