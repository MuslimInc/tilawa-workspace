import 'dart:async';

import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'core/services/appsflyer_service.dart';
import 'core/services/athkar_notification_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/firebase_initialization_service.dart';
import 'core/services/luciq_service.dart';
import 'core/services/notification_permission_service.dart';
import 'features/downloads/data/services/downloads_initialization_service.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'firebase_options.dart';
import 'quran_player_app.dart';
import 'router/app_router.dart';

final logger = Logger();

@visibleForTesting
Future<void> bootstrap({
  Function(Widget)? runner,
  Future<void> Function()? diConfigurator,
}) async {
  final void Function(Widget) run = runner ?? runApp;
  final Future<void> Function() configureDI =
      diConfigurator ?? configureDependencies;
  // Wrap entire main in try-catch for catastrophic failures
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize AppRouter (registers JSON types)
    AppRouter.init();

    // Enable edge-to-edge display (Flutter recommended approach)
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // ========================================================================
    // CRITICAL: Must complete before app starts (blocking)
    // ========================================================================

    // Initialize Firebase first, then DI
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      logger.d('Firebase initialized successfully');
    } catch (e, stackTrace) {
      logger.d('CRITICAL: Firebase initialization failed: $e');
      logger.d('Stack trace: $stackTrace');
      // Continue anyway - app can work without Firebase
    }

    // Initialize DI container
    try {
      await configureDI();
      logger.d('DI container initialized successfully');
    } catch (e, stackTrace) {
      logger.d('CRITICAL: DI initialization failed: $e');
      logger.d('Stack trace: $stackTrace');
      // This is critical - without DI, services can't be resolved
      // But we'll try to continue for better error reporting
    }

    // Initialize HydratedStorage (needed for BLoC state persistence)
    try {
      await initializeHydratedStorage();
    } catch (e) {
      logger.d('Warning: HydratedStorage initialization failed: $e');
      // App can work without state persistence
    }

    // Initialize Crashlytics (catches all errors from app start)
    try {
      await initializeCrashlytics();
    } catch (e) {
      logger.d('Warning: Crashlytics initialization failed: $e');
      // App can work without crash reporting
    }

    Bloc.observer = AppBlocObserver();

    // ========================================================================
    // APP STARTS HERE - User sees UI immediately!
    // ========================================================================
    run(const QuranPlayerApp());

    // ========================================================================
    // NON-CRITICAL: Initialize in background after app is visible
    // ========================================================================
    initializeNonCriticalServices();
  } catch (e, stackTrace) {
    // Catastrophic failure - log and try to start app anyway
    logger.d('CATASTROPHIC ERROR in bootstrap(): $e');
    logger.d('Stack trace: $stackTrace');

    // Last resort: try to start the app with minimal initialization
    try {
      run(const QuranPlayerApp());
    } catch (appError) {
      logger.d('Failed to start app: $appError');
      // At this point, nothing we can do
      rethrow;
    }
  }
}

Future<void> main() async {
  await bootstrap();
}

/// Initialize non-critical services in parallel after app launch
/// This reduces perceived startup time significantly
@visibleForTesting
void initializeNonCriticalServices() {
  Future.microtask(() async {
    try {
      // Phase 1: Parallel initialization of independent services
      // Using Dart 3 record-based .wait for clean parallel execution
      await (
        initializeCredentialManager(),
        initializeAnalytics(),
        initializeAppsFlyer(),
        initializeLuciq(),
      ).wait;

      logger.d('Phase 1 services initialized (parallel)');

      // Phase 2: Services that depend on user permissions or Phase 1
      await requestNotificationPermission();

      // Phase 3: Parallel initialization of notification & downloads
      await (
        initializeNotificationService(),
        initializeDownloads(),
        initializeAthkarNotifications(),
      ).wait;

      logger.d('Phase 2 & 3 services initialized');

      // Phase 4: Firebase data (lowest priority, fire-and-forget)
      await initializeFirebaseDataAsync();

      logger.d('All non-critical services initialized successfully');
    } catch (e) {
      logger.d('Error during non-critical service initialization: $e');
      // App continues to work even if these fail
    }
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Initialize Notification Service
@visibleForTesting
Future<void> initializeNotificationService() async {
  try {
    final NotificationsRepository notificationsRepository =
        getIt<NotificationsRepository>();
    await notificationsRepository.requestPermission();
    await notificationsRepository.getToken();
    await notificationsRepository.initializeListeners();
    logger.d('Notification Repository initialized successfully');
  } catch (e) {
    logger.d('Warning: Could not initialize Notification Repository: $e');
  }
}

/// Initialize HydratedStorage for bloc state persistence
@visibleForTesting
Future<void> initializeHydratedStorage() async {
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
@visibleForTesting
Future<void> initializeCredentialManager() async {
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
@visibleForTesting
Future<void> initializeCrashlytics() async {
  try {
    final CrashlyticsService crashlyticsService = getIt<CrashlyticsService>();
    await crashlyticsService.initialize();
    logger.d('Crashlytics initialized successfully');
  } catch (e) {
    logger.d('Crashlytics initialization error: $e');
  }
}

/// Initialize Analytics
@visibleForTesting
Future<void> initializeAnalytics() async {
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
@visibleForTesting
Future<void> requestNotificationPermission() async {
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
@visibleForTesting
Future<void> initializeFirebaseDataAsync() async {
  try {
    final FirebaseInitializationService firebaseInitService =
        getIt<FirebaseInitializationService>();
    await firebaseInitService.initializeFirebaseData();
  } catch (e) {
    logger.d('Warning: Could not initialize Firebase data: $e');
  }
}

/// Initialize downloads feature
@visibleForTesting
Future<void> initializeDownloads() async {
  try {
    final DownloadsInitializationService downloadsInitService =
        getIt<DownloadsInitializationService>();
    await downloadsInitService.initialize();
  } catch (e) {
    logger.d('Warning: Could not initialize downloads: $e');
  }
}

/// Initialize AppsFlyer attribution tracking
@visibleForTesting
Future<void> initializeAppsFlyer() async {
  try {
    final AppsFlyerService appsFlyerService = getIt<AppsFlyerService>();
    await appsFlyerService.initialize();
    await appsFlyerService.startTracking();
    logger.d('AppsFlyer initialized and tracking started');
  } catch (e) {
    logger.d('Warning: Could not initialize AppsFlyer: $e');
  }
}

/// Initialize Luciq bug reporting
@visibleForTesting
Future<void> initializeLuciq() async {
  try {
    final LuciqService luciqService = getIt<LuciqService>();
    await luciqService.initialize();
    logger.d('Luciq initialized successfully');
  } catch (e) {
    logger.d('Warning: Could not initialize Luciq: $e');
  }
}

/// Initialize athkar notification scheduling
@visibleForTesting
Future<void> initializeAthkarNotifications() async {
  try {
    final AthkarNotificationService athkarService =
        getIt<AthkarNotificationService>();
    await athkarService.initialize();
    await athkarService.scheduleAthkarNotifications();
    logger.d('Athkar notifications scheduled successfully');
  } catch (e) {
    logger.d('Warning: Could not initialize athkar notifications: $e');
  }
}
