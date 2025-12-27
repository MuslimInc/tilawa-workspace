import 'dart:async';

import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/observers/app_bloc_observer.dart';
import 'core/services/analytics_initialization_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/firebase_initialization_service.dart';
import 'core/services/notification_permission_service.dart';
import 'features/downloads/data/services/downloads_initialization_service.dart';
import 'firebase_options.dart';
import 'quran_player_app.dart';
import 'router/app_router.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppRouter (registers JSON types)
  AppRouter.init();

  // Enable edge-to-edge display (Flutter recommended approach)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

  // Initialize downloads feature (resumes pending downloads)
  await _initializeDownloads();

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
    final CredentialManager credentialManager = getIt<CredentialManager>();
    await credentialManager.init(
      preferImmediatelyAvailableCredentials: true,
      googleClientId: AppStrings.googleClientId,
    );
    logger.d('Credential Manager initialized successfully');
  } catch (e) {
    logger.d('Warning: Could not initialize Credential Manager: $e');
  }
}

/// Initialize Crashlytics
Future<void> _initializeCrashlytics() async {
  try {
    final CrashlyticsService crashlyticsService = getIt<CrashlyticsService>();
    await crashlyticsService.initialize();
    logger.d('Crashlytics initialized successfully');
  } catch (e) {
    logger.d('Crashlytics initialization error: $e');
  }
}

/// Initialize Analytics
Future<void> _initializeAnalytics() async {
  try {
    final AnalyticsInitializationService analyticsInitService =
        getIt<AnalyticsInitializationService>();
    await analyticsInitService.initialize();
    logger.d('Analytics initialized successfully');
  } catch (e) {
    logger.d('Analytics initialization error: $e');
  }
}

/// Request notification permission on first launch
Future<void> _requestNotificationPermission() async {
  try {
    final NotificationPermissionService notificationPermissionService =
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
      final FirebaseInitializationService firebaseInitService =
          getIt<FirebaseInitializationService>();
      await firebaseInitService.initializeFirebaseData();
    } catch (e) {
      logger.d('Warning: Could not initialize Firebase data: $e');
    }
  });
}

/// Initialize downloads feature
Future<void> _initializeDownloads() async {
  try {
    final DownloadsInitializationService downloadsInitService =
        getIt<DownloadsInitializationService>();
    await downloadsInitService.initialize();
  } catch (e) {
    logger.d('Warning: Could not initialize downloads: $e');
  }
}
