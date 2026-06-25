import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as local_notifications;
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/bootstrap/app_bootstrapper.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/bootstrap/cold_start_navigation_metrics.dart';
import 'package:tilawa/core/bootstrap/critical_init_coordinator.dart';
import 'package:tilawa/core/bootstrap/first_frame_log.dart';
import 'package:tilawa/core/bootstrap/launch_first_frame_gate.dart';
import 'package:tilawa/core/bootstrap/launch_splash_canvas.dart';
import 'package:tilawa/core/bootstrap/launch_timeline.dart';
import 'package:tilawa/core/bootstrap/logo_height_log.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/bootstrap/startup_launch_coordinator.dart';
import 'package:tilawa/core/debug/device_preview_app_builder.dart';
import 'package:tilawa/core/telemetry/startup_perf_log.dart';
import 'package:tilawa/core/telemetry/startup_telemetry.dart';
import 'package:tilawa/features/auth/data/services/pending_session_revoke_store.dart';
import 'package:tilawa/features/notifications/data/fcm_session_revoked_message.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../firebase_options.dart';
import '../../router/app_router.dart';
import '../../tilawa_app.dart';
import '../di/injection.dart';
import '../di/quran_image_dependencies_module.dart';
import '../logging/app_logger.dart';

part 'app_bootstrapper_phases.dart';
part 'app_startup_phases.dart';
part 'app_startup_widgets.dart';

typedef AppRunner = void Function(Widget widget);
typedef DiConfigurator = Future<void> Function({AppLaunchConfig? launchConfig});

AppLaunchConfig _appLaunchConfig = AppLaunchConfig.fromEnvironment();
AppStartupTasks _startupTasks = AppStartupTasks(launchConfig: _appLaunchConfig);
AppBootstrapper _bootstrapper = AppBootstrapper(startupTasks: _startupTasks);

void configureAppLaunch({AppLaunchConfig? launchConfig}) {
  _appLaunchConfig = launchConfig ?? AppLaunchConfig.fromEnvironment();
  _startupTasks = AppStartupTasks(launchConfig: _appLaunchConfig);
  _bootstrapper = AppBootstrapper(startupTasks: _startupTasks);
}

/// The current launch configuration.
///
/// Defaults to [AppLaunchConfig.fromEnvironment] if not explicitly configured.
AppLaunchConfig get appLaunchConfig => _appLaunchConfig;

Future<void> bootstrap({
  AppRunner? runner,
  DiConfigurator? diConfigurator,
  AppLaunchConfig? launchConfig,
}) async {
  logger.d('[AppLaunch] source=bootstrap: Start in (${DateTime.now()})');
  if (launchConfig != null) {
    configureAppLaunch(launchConfig: launchConfig);
  }
  await _bootstrapper.bootstrap(runner: runner, diConfigurator: diConfigurator);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.d(
    '[AppLaunch] source=firebaseMessagingBackgroundHandler: Start in (${DateTime.now()})',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await persistBackgroundSessionRevokeIfNeeded(
    Map<String, dynamic>.from(message.data),
  );
  if (message.data['actionType'] == 'incoming_quran_session_call') {
    // Show local notification for incoming call
    await _showIncomingCallNotification(message);
  }
}

Future<void> _showIncomingCallNotification(RemoteMessage message) async {
  final data = message.data;
  final title = data['title'] ?? 'Incoming Quran Session call';
  final body = data['body'] ?? 'The other participant is waiting for you.';
  final sessionId = data['sessionId'];

  if (sessionId == null) return;

  final flutterLocalNotificationsPlugin =
      local_notifications.FlutterLocalNotificationsPlugin();
  // We must re-initialize since this is a separate isolate
  const local_notifications.AndroidInitializationSettings androidSettings =
      local_notifications.AndroidInitializationSettings(
        'ic_launcher_monochrome',
      );
  const local_notifications.InitializationSettings initSettings =
      local_notifications.InitializationSettings(
        android: androidSettings,
      );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
  );

  final androidDetails = local_notifications.AndroidNotificationDetails(
    'quran_session_calls',
    'Incoming Calls',
    channelDescription: 'Incoming Quran Session calls',
    importance: local_notifications.Importance.max,
    priority: local_notifications.Priority.max,
    fullScreenIntent: true,
    category: local_notifications.AndroidNotificationCategory.call,
    actions: <local_notifications.AndroidNotificationAction>[
      local_notifications.AndroidNotificationAction(
        'accept_call',
        'Join',
        titleColor: Color(0xFF4CAF50),
      ),
      local_notifications.AndroidNotificationAction(
        'decline_call',
        'Decline',
        titleColor: Color(0xFFF44336),
      ),
    ],
  );

  final platformDetails = local_notifications.NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    id: sessionId.hashCode,
    title: title,
    body: body,
    notificationDetails: platformDetails,
    payload: jsonEncode({
      'actionType': 'incoming_quran_session_call',
      'sessionId': sessionId,
    }),
  );
}

/// Marks [PendingSessionRevokeStore] when a background FCM revokes the session.
@visibleForTesting
Future<void> persistBackgroundSessionRevokeIfNeeded(
  Map<String, dynamic> data,
) async {
  if (isSessionRevokedFcmMessage(data)) {
    await PendingSessionRevokeStore.mark();
  }
}

@visibleForTesting
Future<void> initializeNotificationService() {
  logger.d(
    '[AppLaunch] source=initializeNotificationService: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeNotificationService();
}

@visibleForTesting
void resetMemoizedInitFutures() {
  logger.d(
    '[AppLaunch] source=resetMemoizedInitFutures: Start in (${DateTime.now()})',
  );
  _startupTasks.resetMemoizedInitFutures();
}

@visibleForTesting
Future<void> initializeHydratedStorage() {
  logger.d(
    '[AppLaunch] source=initializeHydratedStorage: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeHydratedStorage();
}

/// Waits until [Hive.init] has completed (safe to call multiple times).
Future<void> ensureHiveInitialized() {
  logger.d(
    '[AppLaunch] source=ensureHiveInitialized: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeHive();
}

@visibleForTesting
Future<void> initializeHive() => ensureHiveInitialized();

@visibleForTesting
Future<void> initializeCrashlytics() {
  logger.d(
    '[AppLaunch] source=initializeCrashlytics: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeCrashlytics();
}

@visibleForTesting
Future<void> initializeAnalytics() {
  logger.d(
    '[AppLaunch] source=initializeAnalytics: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeAnalytics();
}

@visibleForTesting
Future<void> requestNotificationPermission() {
  logger.d(
    '[AppLaunch] source=requestNotificationPermission: Start in (${DateTime.now()})',
  );
  return _startupTasks.requestNotificationPermission();
}

@visibleForTesting
Future<void> initializeFirebaseDataAsync() {
  logger.d(
    '[AppLaunch] source=initializeFirebaseDataAsync: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeFirebaseDataAsync();
}

@visibleForTesting
Future<void> initializeDownloads() {
  logger.d(
    '[AppLaunch] source=initializeDownloads: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeDownloads();
}

@visibleForTesting
Future<void> prepareNotificationLaunchState() {
  logger.d(
    '[AppLaunch] source=prepareNotificationLaunchState: Start in (${DateTime.now()})',
  );
  return _startupTasks.prepareNotificationLaunchState();
}

Future<void> initializeNotificationHandlers() {
  logger.d(
    '[AppLaunch] source=initializeNotificationHandlers: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeNotificationHandlers();
}

@visibleForTesting
Future<void> initializeAudioService() {
  logger.d(
    '[AppLaunch] source=initializeAudioService: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeAudioService();
}

@visibleForTesting
Future<void> initializeAthkarNotifications() {
  logger.d(
    '[AppLaunch] source=initializeAthkarNotifications: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeAthkarNotifications();
}

@visibleForTesting
void initializeNonCriticalServices() {
  logger.d(
    '[AppLaunch] source=initializeNonCriticalServices: Start in (${DateTime.now()})',
  );
  _startupTasks.initializeNonCriticalServices();
}
