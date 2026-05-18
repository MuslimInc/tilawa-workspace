import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_image/core/di/dependency_injection.dart'
    as quran_image_di;
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/domain/usecases/prepare_quran_image_cache.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/bootstrap/launch_timeline.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/services/app_orientation_service.dart';
import 'package:tilawa/core/observers/composite_bloc_observer.dart';
import 'package:tilawa/core/observers/crashlytics_bloc_observer.dart';
import 'package:tilawa/core/services/analytics_initialization_service.dart';
import 'package:tilawa/core/services/crashlytics_service.dart';
import 'package:tilawa/core/services/firebase_initialization_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/quran_assets_prefetch_policy_service.dart';
import 'package:tilawa/core/services/quran_assets_prefetch_service.dart';
import 'package:tilawa/features/downloads/data/services/downloads_initialization_service.dart';
import 'package:tilawa/features/downloads/domain/services/download_notification_service_interface.dart';
import 'package:tilawa/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:tilawa/features/notifications/presentation/services/fcm_service.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_notification_watchdog_scheduler.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';
import 'package:tilawa/firebase_options.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/observers/app_bloc_observer.dart';
import 'package:tilawa_core/services/interfaces/athkar_notification_service_interface.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

class AppStartupTasks {
  AppStartupTasks({AppLaunchConfig? launchConfig})
    : launchConfig = launchConfig ?? AppLaunchConfig.fromEnvironment();

  final AppLaunchConfig launchConfig;

  static bool skipNonCriticalServicesForTesting = false;

  static const Duration nonCriticalStartupDelay = Duration(milliseconds: 3200);
  static const Duration notificationLaunchProbeTimeout = Duration(
    milliseconds: 180,
  );
  static const Duration notificationPermissionSoftTimeout = Duration(
    milliseconds: 1500,
  );
  static const Duration notificationPermissionDeferredDelay = Duration(
    seconds: 3,
  );
  static const Duration notificationChannelDeferredDelay = Duration(seconds: 5);

  static const Duration quranAssetsPrefetchDelay = Duration(milliseconds: 400);

  QuranAssetsPrefetchService? _quranAssetsPrefetchService;
  QuranAssetsPrefetchPolicyService? _quranAssetsPrefetchPolicyService;

  Future<void>? _notificationServiceInitFuture;
  Future<void>? _notificationHandlersInitFuture;
  Future<void>? _crashlyticsInitFuture;
  Future<void>? _analyticsInitFuture;
  Future<void>? _notificationPermissionFuture;

  void resetLaunchState() {
    logger.d(
      '[AppLaunch] source=AppStartupTasks.resetLaunchState: Start in (${DateTime.now()})',
    );
    AppRouter.disableStateRestoration = false;
    AppRouter.pendingStartupNotificationLaunch = false;
    AppRouter.pendingFcmMessage = null;
    AppRouter.pendingLocalNotificationResponse = null;
    AppRouter.lastProcessedNotificationId = null;
  }

  /// Clears memoized init futures. Tests re-stub getIt between cases and need
  /// the one-shot helpers below to actually run each time. Not intended for
  /// runtime use.
  void resetMemoizedInitFutures() {
    logger.d(
      '[AppLaunch] source=AppStartupTasks.resetMemoizedInitFutures: Start in (${DateTime.now()})',
    );
    _notificationServiceInitFuture = null;
    _notificationHandlersInitFuture = null;
    _crashlyticsInitFuture = null;
    _analyticsInitFuture = null;
    _notificationPermissionFuture = null;
  }

  Future<void> initializeFirebase() async {
    if (!_isEnabled(launchConfig.firebaseInit, 'FIREBASE_INIT')) return;
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeFirebase: Start in (${DateTime.now()})',
    );
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> configureForegroundMessaging() async {
    if (!_isEnabled(launchConfig.foregroundMessaging, 'FOREGROUND_MESSAGING')) {
      AppRouter.init();
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.configureForegroundMessaging: Start in (${DateTime.now()})',
    );
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
    if (!_isEnabled(launchConfig.blocObserver, 'BLOC_OBSERVER')) return;
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeBlocObserver: Start in (${DateTime.now()})',
    );
    Bloc.observer = CompositeBlocObserver(
      observers: [
        AppBlocObserver(),
        CrashlyticsBlocObserver(getIt<CrashlyticsService>()),
      ],
    );
  }

  Future<void> configureSystemChrome() {
    if (!_isEnabled(launchConfig.systemChrome, 'SYSTEM_CHROME')) {
      return Future<void>.value();
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.configureSystemChrome: Start in (${DateTime.now()})',
    );
    return Future.wait([
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
      AppOrientationService.applyDefaultOrientations(),
    ]).timeout(const Duration(milliseconds: 1000));
  }

  /// Runs the critical init pipeline that used to live pre-runApp. Order is
  /// important: Firebase must be ready before DI (which registers Firebase*
  /// singletons), and HydratedStorage must be ready before any HydratedBloc
  /// is constructed (which happens when AppProviders mount).
  Future<void> runCriticalInit({
    required DiConfigurator configureDI,
    required LaunchTimeline timeline,
  }) async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks.runCriticalInit: Start in (${DateTime.now()})',
    );
    final bool firebaseOk = await initializeFirebaseAndHydratedStorage(
      timeline,
    );
    await configurePostFirebaseServices(
      firebaseOk: firebaseOk,
      timeline: timeline,
    );
    await runDependencyInjection(configureDI: configureDI, timeline: timeline);
    await configurePreRenderServices(timeline: timeline);
    timeline.logTotal('=== Critical init done');
  }

  void initializeNonCriticalServices() {
    if (!_isEnabled(
      launchConfig.nonCriticalServices,
      'NON_CRITICAL_SERVICES',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeNonCriticalServices: Start in (${DateTime.now()})',
    );
    if (AppStartupTasks.skipNonCriticalServicesForTesting) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future<void>.delayed(
          AppStartupTasks.skipNonCriticalServicesForTesting
              ? Duration.zero
              : nonCriticalStartupDelay,
          () {
            return _initializeNonCriticalServicesInBackground();
          },
        ),
      );
    });
  }

  Future<void> _initializeNonCriticalServicesInBackground() async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks._initializeNonCriticalServicesInBackground: Start in (${DateTime.now()})',
    );
    final LaunchTimeline timeline = LaunchTimeline()..startPhase();

    _scheduleDeferredBackgroundTasks();

    await runPhase0Hive(timeline);
    await runPhase1CredentialAndAnalytics(timeline);
    await runPhase3NotificationsAndAudio(timeline);
    await _runPhase4QuranAndFirebase(timeline);

    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeNonCriticalServices: '
      'All non-critical services completed at (${DateTime.now()})',
    );
  }

  /// Schedules deferred tasks that don't need to block the main flow.
  void _scheduleDeferredBackgroundTasks() {
    logger.d(
      '[AppLaunch] source=AppStartupTasks._scheduleDeferredBackgroundTasks: Start in (${DateTime.now()})',
    );
    // Defer Android notification channel creation well past first interactive
    // frames to avoid startup frame contention.
    if (launchConfig.deferredNotificationChannel) {
      unawaited(_createNotificationChannelDeferred());
    } else {
      _logDisabled('DEFERRED_NOTIFICATION_CHANNEL');
    }

    // Keep crash reporting out of cold-start critical path.
    if (launchConfig.crashlyticsInit) {
      unawaited(initializeCrashlytics());
    } else {
      _logDisabled('CRASHLYTICS_INIT');
    }

    if (launchConfig.prayerNotificationsInit) {
      unawaited(_ensurePrayerNotificationWatchdogScheduled());
    } else {
      _logDisabled('PRAYER_NOTIFICATION_WATCHDOG');
    }
  }

  Future<void> _ensurePrayerNotificationWatchdogScheduled() async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks._ensurePrayerNotificationWatchdogScheduled: Start in (${DateTime.now()})',
    );
    try {
      final PrayerNotificationWatchdogScheduler scheduler =
          getIt<PrayerNotificationWatchdogScheduler>();
      await scheduler.ensurePeriodicWatchdogScheduled();
      logger.d(
        '[AppLaunch] source=AppStartupTasks._ensurePrayerNotificationWatchdogScheduled: Scheduled at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks._ensurePrayerNotificationWatchdogScheduled: Warning: Could not schedule watchdog at (${DateTime.now()}): $e',
      );
    }
  }

  /// Phase 4: Load Quran data, schedule prefetch, init Firebase data, request permissions.
  Future<void> _runPhase4QuranAndFirebase(LaunchTimeline timeline) async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks._runPhase4QuranAndFirebase: Start in (${DateTime.now()})',
    );
    try {
      if (launchConfig.quranDataLoad) {
        timeline.resetPhase();
        await quranQcfLocator<MushafService>().ensureLoaded();
        timeline.log('Phase4 quranData');
      } else {
        _logDisabled('QURAN_DATA_LOAD');
      }

      if (launchConfig.quranAssetsPrefetch) {
        unawaited(_prefetchQuranAssetsDeferred());
        timeline.log('Phase4 quranAssetsPrefetch scheduled');
      } else {
        _logDisabled('QURAN_ASSETS_PREFETCH');
      }

      // Stagger second wave of background data
      await Future<void>.delayed(const Duration(milliseconds: 200));

      if (launchConfig.firebaseDataInit) {
        timeline.resetPhase();
        await initializeFirebaseDataAsync();
        timeline.log('Phase4 firebaseData');
      } else {
        _logDisabled('FIREBASE_DATA_INIT');
      }

      // Keep permission probing away from first-route interaction frames.
      if (launchConfig.notificationPermissionRequest) {
        timeline.resetPhase();
        await Future<void>.delayed(
          AppStartupTasks.skipNonCriticalServicesForTesting
              ? Duration.zero
              : notificationPermissionDeferredDelay,
        );
        await requestNotificationPermission();
        timeline.log('Phase5 notificationPermission');
      } else {
        _logDisabled('NOTIFICATION_PERMISSION_REQUEST');
      }
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks._runPhase4QuranAndFirebase: Phase4 error at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> _prefetchQuranAssetsDeferred() async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks._prefetchQuranAssetsDeferred: Start in (${DateTime.now()})',
    );
    try {
      await Future<void>.delayed(quranAssetsPrefetchDelay);
      await _assetPrefetchService.prefetchInBackground();
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks._runPhase4QuranAndFirebase: Quran asset prefetch skipped/failed at (${DateTime.now()}): $e',
      );
    }
  }

  QuranAssetsPrefetchService get _assetPrefetchService {
    return _quranAssetsPrefetchService ??= QuranAssetsPrefetchService(
      connectivity: getIt(),
      prepareQuranImageCacheUseCase: quran_image_di
          .sl<PrepareQuranImageCacheUseCase>(),
      imageCacheRepository: quran_image_di.sl<QuranImageCacheRepository>(),
      quranFontService: quranQcfLocator<QuranFontService>(),
      policyService: _assetPrefetchPolicyService,
    );
  }

  QuranAssetsPrefetchPolicyService get _assetPrefetchPolicyService {
    return _quranAssetsPrefetchPolicyService ??=
        QuranAssetsPrefetchPolicyService();
  }

  Future<void> _createNotificationChannelDeferred() async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks._createNotificationChannelDeferred: Start in (${DateTime.now()})',
    );
    try {
      await Future<void>.delayed(
        AppStartupTasks.skipNonCriticalServicesForTesting
            ? Duration.zero
            : notificationChannelDeferredDelay,
      );
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      await dispatcher.initialize();
      logger.d(
        '[AppLaunch] source=AppStartupTasks._createNotificationChannelDeferred: Deferred notification channel ensured at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks._createNotificationChannelDeferred: Warning: Could not create deferred notification channel at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> initializeNotificationService() async {
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeNotificationService: Start in (${DateTime.now()})',
    );
    if (!_isEnabled(
      launchConfig.notificationServiceInit,
      'NOTIFICATION_SERVICE_INIT',
    )) {
      return;
    }
    return _notificationServiceInitFuture ??= () async {
      try {
        final NotificationsRepository notificationsRepository =
            getIt<NotificationsRepository>();
        await notificationsRepository.requestPermission();
        await notificationsRepository.getToken();
        await notificationsRepository.initializeListeners();

        final FCMService fcmService = getIt<FCMService>();
        fcmService.initialize();

        logger.d(
          '[AppLaunch] source=AppStartupTasks.initializeNotificationService: Notification services initialized successfully at (${DateTime.now()})',
        );
      } catch (e) {
        logger.d(
          '[AppLaunch] source=AppStartupTasks.initializeNotificationService: Warning: Could not initialize Notification services at (${DateTime.now()}): $e',
        );
      }
    }();
  }

  Future<void> initializeHydratedStorage() async {
    if (!_isEnabled(
      launchConfig.hydratedStorageInit,
      'HYDRATED_STORAGE_INIT',
    )) {
      HydratedBloc.storage = _InMemoryStorage();
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeHydratedStorage: Start in (${DateTime.now()})',
    );
    try {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: kIsWeb
            ? HydratedStorageDirectory.web
            : HydratedStorageDirectory(
                (await getApplicationDocumentsDirectory()).path,
              ),
      );

      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeHydratedStorage: HydratedStorage initialized successfully at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeHydratedStorage: Warning: Could not initialize HydratedStorage, using in-memory fallback at (${DateTime.now()}): $e',
      );
      HydratedBloc.storage = _InMemoryStorage();
    }
  }

  Future<void> initializeHive() async {
    if (!_isEnabled(launchConfig.hiveInit, 'HIVE_INIT')) return;
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeHive: Start in (${DateTime.now()})',
    );
    try {
      final directory = kIsWeb
          ? null
          : await getApplicationDocumentsDirectory();
      if (!kIsWeb && directory != null) {
        Hive.init(directory.path);
      }
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeHive: Hive initialized successfully at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeHive: Warning: Could not initialize Hive at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> initializeCredentialManager() async {
    if (!_isEnabled(
      launchConfig.credentialManagerInit,
      'CREDENTIAL_MANAGER_INIT',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeCredentialManager: Start in (${DateTime.now()})',
    );
    try {
      final CredentialManager credentialManager = getIt<CredentialManager>();
      await credentialManager.init(
        preferImmediatelyAvailableCredentials: true,
        googleClientId: AppStrings.googleClientId,
      );
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeCredentialManager: Credential Manager initialized successfully at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeCredentialManager: Warning: Could not initialize Credential Manager at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> initializeCrashlytics() async {
    if (!_isEnabled(launchConfig.crashlyticsInit, 'CRASHLYTICS_INIT')) return;
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeCrashlytics: Start in (${DateTime.now()})',
    );
    return _crashlyticsInitFuture ??= () async {
      try {
        final CrashlyticsService crashlyticsService =
            getIt<CrashlyticsService>();
        await crashlyticsService.initialize();
      } catch (e) {
        logger.d(
          '[AppLaunch] source=AppStartupTasks.initializeCrashlytics: Crashlytics initialization error at (${DateTime.now()}): $e',
        );
      }
    }();
  }

  Future<void> initializeAnalytics() async {
    if (!_isEnabled(launchConfig.analyticsInit, 'ANALYTICS_INIT')) return;
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeAnalytics: Start in (${DateTime.now()})',
    );
    return _analyticsInitFuture ??= () async {
      try {
        final AnalyticsInitializationService analyticsInitService =
            getIt<AnalyticsInitializationService>();
        await analyticsInitService.initialize();
      } catch (e) {
        logger.d(
          '[AppLaunch] source=AppStartupTasks.initializeAnalytics: Analytics initialization error at (${DateTime.now()}): $e',
        );
      }
    }();
  }

  Future<void> requestNotificationPermission() async {
    if (!_isEnabled(
      launchConfig.notificationPermissionRequest,
      'NOTIFICATION_PERMISSION_REQUEST',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.requestNotificationPermission: Start in (${DateTime.now()})',
    );
    return _notificationPermissionFuture ??= () async {
      try {
        final NotificationPermissionService notificationPermissionService =
            getIt<NotificationPermissionService>();
        await notificationPermissionService
            .requestPermissionIfNecessary()
            .timeout(
              notificationPermissionSoftTimeout,
              onTimeout: () {
                logger.d(
                  'Notification permission request still pending (deferred)',
                );
              },
            );
        logger.d(
          '[AppLaunch] source=AppStartupTasks.requestNotificationPermission: Notification permission request completed at (${DateTime.now()})',
        );
      } catch (e) {
        logger.d(
          '[AppLaunch] source=AppStartupTasks.requestNotificationPermission: Warning: Could not request notification permission at (${DateTime.now()}): $e',
        );
      }
    }();
  }

  Future<void> initializeFirebaseDataAsync() async {
    if (!_isEnabled(launchConfig.firebaseDataInit, 'FIREBASE_DATA_INIT')) {
      return;
    }
    if (!_isEnabled(
      launchConfig.subscriptionServiceEnabled,
      'SUBSCRIPTION_SERVICE',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeFirebaseDataAsync: Start in (${DateTime.now()})',
    );
    try {
      final FirebaseInitializationService firebaseInitService =
          getIt<FirebaseInitializationService>();
      await firebaseInitService.initializeFirebaseData();
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeFirebaseDataAsync: Warning: Could not initialize Firebase data at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> initializeDownloads() async {
    if (!_isEnabled(launchConfig.downloadsInit, 'DOWNLOADS_INIT')) return;
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeDownloads: Start in (${DateTime.now()})',
    );
    try {
      final DownloadsInitializationService downloadsInitService =
          getIt<DownloadsInitializationService>();
      await downloadsInitService.initialize();
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeDownloads: Warning: Could not initialize downloads at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> prepareNotificationLaunchState() async {
    if (!_isEnabled(
      launchConfig.notificationLaunchProbe,
      'NOTIFICATION_LAUNCH_PROBE',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.prepareNotificationLaunchState: Start in (${DateTime.now()})',
    );
    try {
      // Keep pre-runApp on a fast path: only probe FCM cold-start payload.
      // Local notification launch probing is deferred until after first frame.
      final RemoteMessage? fcmInitialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(notificationLaunchProbeTimeout, onTimeout: () => null);

      if (fcmInitialMessage != null) {
        AppRouter.disableStateRestoration = true;
        AppRouter.pendingStartupNotificationLaunch = true;
        AppRouter.pendingFcmMessage = fcmInitialMessage;
      }

      logger.d(
        '[AppLaunch] source=AppStartupTasks.prepareNotificationLaunchState: Notification launch state prepared (fcm-only) at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.prepareNotificationLaunchState: Warning: Could not prepare notification launch state at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> initializeNotificationHandlers() async {
    if (!_isEnabled(
      launchConfig.notificationHandlersInit,
      'NOTIFICATION_HANDLERS_INIT',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeNotificationHandlers: Start in (${DateTime.now()})',
    );
    return _notificationHandlersInitFuture ??= () async {
      try {
        // Keep early notification handler startup lightweight. Channel creation
        // is deferred separately by _createNotificationChannelDeferred().
        final INotificationDispatcher dispatcher =
            getIt<INotificationDispatcher>();
        await dispatcher.initialize(createHighImportanceChannel: false);

        final IAthkarNotificationService athkarService =
            getIt<IAthkarNotificationService>();
        await athkarService.initialize();

        final IPrayerAdhanNotificationService prayerService =
            getIt<IPrayerAdhanNotificationService>();
        await prayerService.initialize();

        final IDownloadNotificationService downloadNotificationService =
            getIt<IDownloadNotificationService>();
        await downloadNotificationService.initialize();

        logger.d(
          '[AppLaunch] source=AppStartupTasks.initializeNotificationHandlers: Notification handlers initialized at (${DateTime.now()})',
        );
      } catch (e) {
        logger.d(
          '[AppLaunch] source=AppStartupTasks.initializeNotificationHandlers: Warning: Could not initialize notification handlers at (${DateTime.now()}): $e',
        );
      }
    }();
  }

  Future<void> initializeAudioService() async {
    if (!_isEnabled(launchConfig.audioServiceInit, 'AUDIO_SERVICE_INIT')) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeAudioService: Start in (${DateTime.now()})',
    );
    try {
      final handler = getIt<AudioPlayerHandler>();
      await AudioService.init(
        builder: () => handler as AudioHandler,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.tilawa.app.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationOngoing: true,
        ),
      );
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeAudioService: Audio service initialized successfully at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeAudioService: Warning: Could not initialize audio service at (${DateTime.now()}): $e',
      );
    }
  }

  Future<void> initializeAthkarNotifications() async {
    if (!_isEnabled(
      launchConfig.athkarNotificationsInit,
      'ATHKAR_NOTIFICATIONS_INIT',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializeAthkarNotifications: Start in (${DateTime.now()})',
    );
    try {
      final IAthkarNotificationService athkarService =
          getIt<IAthkarNotificationService>();
      await athkarService.scheduleAthkarNotifications();
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeAthkarNotifications: Athkar notifications scheduled successfully at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializeAthkarNotifications: Warning: Could not initialize athkar notifications at (${DateTime.now()}): $e',
      );
    }
  }

  /// Initializes the prayer adhan notification service.
  ///
  /// Called in Phase 3 alongside athkar and notification service init.
  /// Also performs a deduped schedule pass from saved settings/location so
  /// cold start, reboot, date change, and timezone change do not depend on the
  /// Prayer Times tab being opened.
  Future<void> initializePrayerNotifications() async {
    if (!_isEnabled(
      launchConfig.prayerNotificationsInit,
      'PRAYER_NOTIFICATIONS_INIT',
    )) {
      return;
    }
    logger.d(
      '[AppLaunch] source=AppStartupTasks.initializePrayerNotifications: Start in (${DateTime.now()})',
    );
    try {
      final IPrayerAdhanNotificationService service =
          getIt<IPrayerAdhanNotificationService>();
      await service.initialize();
      final LoadPrayerSettingsUseCase loadSettings =
          getIt<LoadPrayerSettingsUseCase>();
      final SchedulePrayerNotificationsUseCase scheduleNotifications =
          getIt<SchedulePrayerNotificationsUseCase>();
      final IAdhanAlarmPlayer adhanPlayer = getIt<IAdhanAlarmPlayer>();

      // If the device booted (or the package was replaced/timezone changed)
      // since the last time we ran, the dedup fingerprint is stale relative
      // to AlarmManager state. Force a reschedule so the schedule is rebuilt
      // from scratch instead of being skipped.
      bool forceReschedule = false;
      try {
        forceReschedule = await adhanPlayer.consumeNeedsRescheduleAfterBoot();
        if (forceReschedule) {
          logger.d(
            '[AppLaunch] source=AppStartupTasks.initializePrayerNotifications: '
            'Boot/timezone change detected — forcing reschedule',
          );
        }
      } catch (_) {}

      final result = await loadSettings.call();
      await result.fold(
        (failure) async {
          logger.d(
            '[AppLaunch] source=AppStartupTasks.initializePrayerNotifications: Warning: Could not load prayer settings for startup schedule: ${failure.message}',
          );
        },
        (PrayerSettingsEntity settings) async {
          final double? latitude = settings.effectiveSchedulingLatitude;
          final double? longitude = settings.effectiveSchedulingLongitude;
          if (latitude == null || longitude == null) {
            if (forceReschedule) {
              await adhanPlayer.markNeedsReschedule();
            }
            logger.d(
              '[AppLaunch] source=AppStartupTasks.initializePrayerNotifications: No saved location; startup schedule skipped',
            );
            return;
          }
          final scheduleResult = await scheduleNotifications.call(
            settings: settings,
            latitude: latitude,
            longitude: longitude,
            forceReschedule: forceReschedule,
          );
          if (forceReschedule && scheduleResult.isLeft) {
            await adhanPlayer.markNeedsReschedule();
          }
        },
      );
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializePrayerNotifications: Prayer notifications initialized at (${DateTime.now()})',
      );
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupTasks.initializePrayerNotifications: Warning: Could not initialize prayer notifications at (${DateTime.now()}): $e',
      );
    }
  }

  bool _isEnabled(bool isEnabled, String toggleName) {
    if (!isEnabled) {
      _logDisabled(toggleName);
    }
    return isEnabled;
  }

  void _logDisabled(String toggleName) {
    logger.d(
      '[AppLaunch] source=Config: Disabled by config: $toggleName at (${DateTime.now()})',
    );
  }
}

/// In-memory fallback for [HydratedBloc.storage] when persistent storage
/// fails to initialize. State will not survive app restarts but the app
/// will not crash.
class _InMemoryStorage implements Storage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<void> close() async {}
}
