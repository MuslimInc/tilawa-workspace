import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/bootstrap/app_bootstrapper.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/bootstrap/cold_start_navigation_metrics.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/bootstrap/critical_init_coordinator.dart';
import 'package:tilawa/core/bootstrap/launch_timeline.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../firebase_options.dart';
import '../../router/app_router.dart';
import '../../tilawa_app.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';

import '../di/injection.dart';
import '../di/quran_image_dependencies_module.dart';
import '../logging/app_logger.dart';

part 'app_bootstrapper_phases.dart';
part 'app_startup_phases.dart';
part 'app_startup_widgets.dart';

typedef AppRunner = void Function(Widget widget);
typedef DiConfigurator =
    Future<void> Function({AppLaunchConfig? launchConfig});

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

@visibleForTesting
Future<void> initializeHive() {
  logger.d('[AppLaunch] source=initializeHive: Start in (${DateTime.now()})');
  return _startupTasks.initializeHive();
}

@visibleForTesting
Future<void> initializeCredentialManager() {
  logger.d(
    '[AppLaunch] source=initializeCredentialManager: Start in (${DateTime.now()})',
  );
  return _startupTasks.initializeCredentialManager();
}

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
