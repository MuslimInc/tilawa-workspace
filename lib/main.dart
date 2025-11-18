import 'dart:async';

import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/core/observers/app_bloc_observer.dart';
import 'package:muzakri/core/services/analytics_initialization_service.dart';
import 'package:muzakri/core/services/crashlytics_service.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/core/services/notification_permission_service.dart';
import 'package:muzakri/firebase_options.dart';
import 'package:muzakri/quran_player_app.dart';
import 'package:path_provider/path_provider.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge display (Flutter recommended approach)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Firebase first, then DI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  // Initialize HydratedStorage
  await _initializeHydratedStorage();

  // Initialize Crashlytics first (handles error reporting)
  await _initializeCrashlytics();

  // Initialize Credential Manager
  await _initializeCredentialManager();

  // Initialize Analytics
  await _initializeAnalytics();

  // Request notification permission on first launch
  await _requestNotificationPermission();

  // Initialize Firebase data asynchronously after app starts
  _initializeFirebaseDataAsync();

  Bloc.observer = AppBlocObserver();

  runApp(const QuranPlayerApp());
}

/// Initialize HydratedStorage for bloc state persistence
Future<void> _initializeHydratedStorage() async {
  try {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: kIsWeb
          ? HydratedStorageDirectory.web
          : HydratedStorageDirectory((await getTemporaryDirectory()).path),
    );

    logger.d('HydratedStorage initialized successfully');
  } catch (e) {
    logger.d('Warning: Could not initialize HydratedStorage: $e');
  }
}

/// Initialize Credential Manager with Google Client ID
Future<void> _initializeCredentialManager() async {
  try {
    final credentialManager = getIt<CredentialManager>();
    await credentialManager.init(
      preferImmediatelyAvailableCredentials: true,
      googleClientId:
          '181575856185-2ioqgr7miir7hj7hvgcsi7qp7juo2gco.apps.googleusercontent.com',
    );
    logger.d('Credential Manager initialized successfully');
  } catch (e) {
    logger.d('Warning: Could not initialize Credential Manager: $e');
  }
}

/// Initialize Crashlytics
Future<void> _initializeCrashlytics() async {
  try {
    final crashlyticsService = getIt<CrashlyticsService>();
    await crashlyticsService.initialize();
    logger.d('Crashlytics initialized successfully');
  } catch (e) {
    logger.d('Crashlytics initialization error: $e');
  }
}

/// Initialize Analytics
Future<void> _initializeAnalytics() async {
  try {
    final analyticsInitService = getIt<AnalyticsInitializationService>();
    await analyticsInitService.initialize();
    logger.d('Analytics initialized successfully');
  } catch (e) {
    logger.d('Analytics initialization error: $e');
  }
}

/// Request notification permission on first launch
Future<void> _requestNotificationPermission() async {
  try {
    final notificationPermissionService =
        getIt<NotificationPermissionService>();
    await notificationPermissionService.requestPermissionOnFirstLaunch();
    logger.d('Notification permission request completed');
  } catch (e) {
    logger.d('Warning: Could not request notification permission: $e');
  }
}

/// Initialize Firebase data asynchronously to avoid blocking main thread
void _initializeFirebaseDataAsync() {
  Future.microtask(() async {
    try {
      final firebaseInitService = getIt<FirebaseInitializationService>();
      await firebaseInitService.initializeFirebaseData();
    } catch (e) {
      logger.d('Warning: Could not initialize Firebase data: $e');
    }
  });
}
