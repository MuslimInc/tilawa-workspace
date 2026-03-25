import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tilawa/features/downloads/domain/services/download_notification_service_interface.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/observers/app_bloc_observer.dart';
import 'package:tilawa_core/services/interfaces/athkar_notification_service_interface.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import '../../features/downloads/data/services/downloads_initialization_service.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/services/fcm_service.dart';
import '../../firebase_options.dart';
import '../../router/app_router.dart';
import '../../shared/audio/audio_player_handler.dart';
import '../../tilawa_app.dart';
import '../di/injection.dart';
import '../logging/app_logger.dart';
import '../observers/composite_bloc_observer.dart';
import '../observers/crashlytics_bloc_observer.dart';
import '../services/analytics_initialization_service.dart';
import '../services/crashlytics_service.dart';
import '../services/firebase_initialization_service.dart';
import '../services/notification_permission_service.dart';

typedef AppRunner = void Function(Widget widget);
typedef DiConfigurator = Future<void> Function();

final AppStartupTasks _startupTasks = AppStartupTasks();
final AppBootstrapper _bootstrapper = AppBootstrapper(
  startupTasks: _startupTasks,
);

Future<void> bootstrap({
  AppRunner? runner,
  DiConfigurator? diConfigurator,
}) async {
  await _bootstrapper.bootstrap(runner: runner, diConfigurator: diConfigurator);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

@visibleForTesting
Future<void> initializeNotificationService() =>
    _startupTasks.initializeNotificationService();

@visibleForTesting
Future<void> initializeHydratedStorage() =>
    _startupTasks.initializeHydratedStorage();

@visibleForTesting
Future<void> initializeHive() => _startupTasks.initializeHive();

@visibleForTesting
Future<void> initializeCredentialManager() =>
    _startupTasks.initializeCredentialManager();

@visibleForTesting
Future<void> initializeCrashlytics() => _startupTasks.initializeCrashlytics();

@visibleForTesting
Future<void> initializeAnalytics() => _startupTasks.initializeAnalytics();

@visibleForTesting
Future<void> requestNotificationPermission() =>
    _startupTasks.requestNotificationPermission();

@visibleForTesting
Future<void> initializeFirebaseDataAsync() =>
    _startupTasks.initializeFirebaseDataAsync();

@visibleForTesting
Future<void> initializeDownloads() => _startupTasks.initializeDownloads();

@visibleForTesting
Future<void> prepareNotificationLaunchState() =>
    _startupTasks.prepareNotificationLaunchState();

Future<void> initializeNotificationHandlers() =>
    _startupTasks.initializeNotificationHandlers();

@visibleForTesting
Future<void> initializeAudioService() => _startupTasks.initializeAudioService();

@visibleForTesting
Future<void> initializeAthkarNotifications() =>
    _startupTasks.initializeAthkarNotifications();

@visibleForTesting
void initializeNonCriticalServices() =>
    _startupTasks.initializeNonCriticalServices();

class AppBootstrapper {
  const AppBootstrapper({required AppStartupTasks startupTasks})
    : _startupTasks = startupTasks;

  final AppStartupTasks _startupTasks;

  Future<void> bootstrap({
    AppRunner? runner,
    DiConfigurator? diConfigurator,
  }) async {
    final AppRunner run = runner ?? runApp;
    final DiConfigurator configureDI = diConfigurator ?? configureDependencies;
    final LaunchTimeline timeline = LaunchTimeline();

    try {
      timeline.startPhase();
      WidgetsFlutterBinding.ensureInitialized();
      _startupTasks.resetLaunchState();
      timeline.log('WidgetsBinding');

      timeline.resetPhase();
      bool firebaseOk = false;

      final Future<void> firebaseFuture = _startupTasks
          .initializeFirebase()
          .then((_) {
            firebaseOk = true;
            timeline.log('Firebase.initializeApp');
          })
          .catchError((Object e, StackTrace stackTrace) {
            timeline.log('Firebase FAILED');
            logger.e(
              'Firebase initialization failed: $e',
              stackTrace: stackTrace,
            );
          });

      final Future<void> hydratedFuture = _startupTasks
          .initializeHydratedStorage()
          .then((_) => timeline.log('HydratedStorage'))
          .catchError((Object e) => timeline.log('HydratedStorage FAILED'));

      await Future.wait([firebaseFuture, hydratedFuture]);
      timeline.log('Phase1 parallel done');

      if (firebaseOk) {
        try {
          timeline.resetPhase();
          await _startupTasks.configureForegroundMessaging();
          timeline.log('FCM setup');
        } catch (e) {
          logger.d('[LaunchApp] FCM setup FAILED: $e');
        }
      } else {
        AppRouter.init();
      }

      timeline.resetPhase();
      await configureDI();
      timeline.log('DI configureDependencies');

      timeline.resetPhase();
      _startupTasks.initializeBlocObserver();

      final Future<void> crashFuture = _startupTasks
          .initializeCrashlytics()
          .then((_) => timeline.log('Crashlytics'))
          .catchError((Object e) => timeline.log('Crashlytics FAILED'));

      final Future<void> notificationFuture = _startupTasks
          .prepareNotificationLaunchState()
          .then((_) => timeline.log('NotificationDispatcher'))
          .catchError(
            (Object e) => timeline.log('NotificationDispatcher FAILED'),
          );

      final Future<void> chromeFuture = _startupTasks
          .configureSystemChrome()
          .then((_) => timeline.log('SystemChrome'))
          .catchError(
            (Object e) => timeline.log('SystemChrome FAILED/timeout'),
          );

      await Future.wait([crashFuture, notificationFuture, chromeFuture]);
      timeline.log('Phase2 parallel (crash+notif+chrome)');

      timeline.logTotal('=== TOTAL before runApp');
      run(_startupTasks.buildRootApp());
      timeline.logTotal('runApp called at');

      _startupTasks.initializeNonCriticalServices();
    } catch (e, stackTrace) {
      logger.f('CATASTROPHIC ERROR in bootstrap(): $e', stackTrace: stackTrace);
      run(_startupTasks.buildFatalErrorApp());
    }
  }
}

class AppStartupTasks {
  const AppStartupTasks();

  void resetLaunchState() {
    AppRouter.disableStateRestoration = false;
    AppRouter.pendingStartupNotificationLaunch = false;
    AppRouter.pendingFcmMessage = null;
    AppRouter.pendingLocalNotificationResponse = null;
    AppRouter.lastProcessedNotificationId = null;
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> configureForegroundMessaging() async {
    AppRouter.init();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  void initializeBlocObserver() {
    Bloc.observer = CompositeBlocObserver(
      observers: [
        AppBlocObserver(),
        CrashlyticsBlocObserver(getIt<CrashlyticsService>()),
      ],
    );
  }

  Future<void> configureSystemChrome() {
    return Future.wait([
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    ]).timeout(const Duration(milliseconds: 1000));
  }

  Widget buildRootApp() {
    return DevicePreview(
      enabled: false,
      builder: (context) => const TilawaApp(),
    );
  }

  Widget buildFatalErrorApp() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Something went wrong.\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  void initializeNonCriticalServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeNonCriticalServicesInBackground());
    });
  }

  Future<void> _initializeNonCriticalServicesInBackground() async {
    final LaunchTimeline timeline = LaunchTimeline()..startPhase();

    try {
      await initializeHive();
      timeline.log('Phase0 hive');
    } catch (e) {
      logger.d(
        '[LaunchApp] Phase0 error after ${timeline.phaseElapsedMs}ms: $e',
      );
    }

    try {
      timeline.resetPhase();
      await (
        initializeCredentialManager(),
        initializeAnalytics(),
        initializeAudioService(),
      ).wait;
      timeline.log('Phase1 (credential+analytics+audio)');
    } catch (e) {
      logger.d(
        '[LaunchApp] Phase1 error after ${timeline.phaseElapsedMs}ms: $e',
      );
    }

    try {
      timeline.resetPhase();
      await requestNotificationPermission();
      timeline.log('Phase2 notificationPermission');
    } catch (e) {
      logger.d('[LaunchApp] Phase2 error: $e');
    }

    try {
      timeline.resetPhase();
      await initializeNotificationService();
      timeline.log('Phase3 notificationService');

      timeline.resetPhase();
      await initializeAthkarNotifications();
      timeline.log('Phase3 athkarNotifications');

      timeline.resetPhase();
      await initializeDownloads();
      timeline.log('Phase3 downloads');
    } catch (e) {
      logger.d('[LaunchApp] Phase3 error: $e');
    }

    try {
      timeline.resetPhase();
      await initializeFirebaseDataAsync();
      timeline.log('Phase4 firebaseData');
    } catch (e) {
      logger.d('[LaunchApp] Phase4 error: $e');
    }

    logger.d('[LaunchApp] === All non-critical services done ===');
  }

  Future<void> initializeNotificationService() async {
    try {
      final NotificationsRepository notificationsRepository =
          getIt<NotificationsRepository>();
      await notificationsRepository.requestPermission();
      await notificationsRepository.getToken();
      await notificationsRepository.initializeListeners();

      final FCMService fcmService = getIt<FCMService>();
      fcmService.initialize();

      logger.d('Notification services initialized successfully');
    } catch (e) {
      logger.d('Warning: Could not initialize Notification services: $e');
    }
  }

  Future<void> initializeHydratedStorage() async {
    try {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: kIsWeb
            ? HydratedStorageDirectory.web
            : HydratedStorageDirectory(
                (await getApplicationDocumentsDirectory()).path,
              ),
      );

      logger.d('HydratedStorage initialized successfully');
    } catch (e) {
      logger.d('Warning: Could not initialize HydratedStorage: $e');
    }
  }

  Future<void> initializeHive() async {
    try {
      final directory = kIsWeb
          ? null
          : await getApplicationDocumentsDirectory();
      if (!kIsWeb && directory != null) {
        Hive.init(directory.path);
      }
      logger.d('Hive initialized successfully');
    } catch (e) {
      logger.d('Warning: Could not initialize Hive: $e');
    }
  }

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

  Future<void> initializeCrashlytics() async {
    try {
      final CrashlyticsService crashlyticsService = getIt<CrashlyticsService>();
      await crashlyticsService.initialize();
      logger.d('Crashlytics initialized successfully');
    } catch (e) {
      logger.d('Crashlytics initialization error: $e');
    }
  }

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

  Future<void> requestNotificationPermission() async {
    try {
      final NotificationPermissionService notificationPermissionService =
          getIt<NotificationPermissionService>();
      await notificationPermissionService.requestPermissionIfNecessary();
      logger.d('Notification permission request completed');
    } catch (e) {
      logger.d('Warning: Could not request notification permission: $e');
    }
  }

  Future<void> initializeFirebaseDataAsync() async {
    try {
      final FirebaseInitializationService firebaseInitService =
          getIt<FirebaseInitializationService>();
      await firebaseInitService.initializeFirebaseData();
    } catch (e) {
      logger.d('Warning: Could not initialize Firebase data: $e');
    }
  }

  Future<void> initializeDownloads() async {
    try {
      final DownloadsInitializationService downloadsInitService =
          getIt<DownloadsInitializationService>();
      await downloadsInitService.initialize();
    } catch (e) {
      logger.d('Warning: Could not initialize downloads: $e');
    }
  }

  Future<void> prepareNotificationLaunchState() async {
    try {
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      await dispatcher.initialize();

      final (NotificationAppLaunchDetails?, RemoteMessage?) launchState =
          await (
            dispatcher.getNotificationAppLaunchDetails().timeout(
              const Duration(milliseconds: 1000),
              onTimeout: () => null,
            ),
            FirebaseMessaging.instance.getInitialMessage().timeout(
              const Duration(milliseconds: 1000),
              onTimeout: () => null,
            ),
          ).wait;

      final NotificationAppLaunchDetails? launchDetails = launchState.$1;
      final RemoteMessage? fcmInitialMessage = launchState.$2;

      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        AppRouter.disableStateRestoration = true;
        AppRouter.pendingStartupNotificationLaunch = true;
        AppRouter.pendingLocalNotificationResponse =
            launchDetails.notificationResponse;
      }

      if (fcmInitialMessage != null) {
        AppRouter.disableStateRestoration = true;
        AppRouter.pendingStartupNotificationLaunch = true;
        AppRouter.pendingFcmMessage = fcmInitialMessage;
      }

      logger.d('Notification launch state prepared');
    } catch (e) {
      logger.d('Warning: Could not prepare notification launch state: $e');
    }
  }

  Future<void> initializeNotificationHandlers() async {
    try {
      final IAthkarNotificationService athkarService =
          getIt<IAthkarNotificationService>();
      await athkarService.initialize();

      final IDownloadNotificationService downloadNotificationService =
          getIt<IDownloadNotificationService>();
      await downloadNotificationService.initialize();

      logger.d('Notification handlers initialized');
    } catch (e) {
      logger.d('Warning: Could not initialize notification handlers: $e');
    }
  }

  Future<void> initializeAudioService() async {
    try {
      final handler = getIt<AudioPlayerHandler>();
      await AudioService.init(
        builder: () => handler as AudioHandler,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationOngoing: true,
        ),
      );
      logger.d('Audio service initialized successfully');
    } catch (e) {
      logger.d('Warning: Could not initialize audio service: $e');
    }
  }

  Future<void> initializeAthkarNotifications() async {
    try {
      final IAthkarNotificationService athkarService =
          getIt<IAthkarNotificationService>();
      await athkarService.scheduleAthkarNotifications();
      logger.d('Athkar notifications scheduled successfully');
    } catch (e) {
      logger.d('Warning: Could not initialize athkar notifications: $e');
    }
  }
}

class LaunchTimeline {
  LaunchTimeline() : total = Stopwatch()..start(), phase = Stopwatch();

  final Stopwatch total;
  final Stopwatch phase;

  int get phaseElapsedMs => phase.elapsedMilliseconds;

  void startPhase() {
    phase.start();
  }

  void resetPhase() {
    phase
      ..reset()
      ..start();
  }

  void log(String label) {
    logger.d('[LaunchApp] $label: ${phase.elapsedMilliseconds}ms');
  }

  void logTotal(String label) {
    logger.d('[LaunchApp] $label: ${total.elapsedMilliseconds}ms');
  }
}
