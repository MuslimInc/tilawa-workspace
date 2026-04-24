import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_image/core/di/dependency_injection.dart'
    as quran_image_di;
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/domain/usecases/prepare_quran_image_cache.dart';
import 'package:quran_qcf/quran_qcf.dart';
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
import '../di/quran_image_dependencies_module.dart';
import '../logging/app_logger.dart';
import '../observers/composite_bloc_observer.dart';
import '../observers/crashlytics_bloc_observer.dart';
import '../services/analytics_initialization_service.dart';
import '../services/crashlytics_service.dart';
import '../services/firebase_initialization_service.dart';
import '../services/notification_permission_service.dart';
import '../services/quran_assets_prefetch_policy_service.dart';
import '../services/quran_assets_prefetch_service.dart';

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
void resetMemoizedInitFutures() => _startupTasks.resetMemoizedInitFutures();

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
      PerfLogger.startFrameWatcher();
      _startupTasks.resetLaunchState();
      timeline.log('WidgetsBinding');

      // Pre-runApp is a fast path: run() as soon as the Flutter binding is
      // ready. Critical init is scheduled to start AFTER the first frame
      // paints so the isolate isn't saturated while the first frame is
      // trying to vsync. Non-critical work (audio, Quran data, analytics,
      // etc.) still runs after that via initializeNonCriticalServices().
      final Completer<Future<void>> criticalInitFutureCompleter =
          Completer<Future<void>>();

      void kickOffCriticalInit() {
        if (criticalInitFutureCompleter.isCompleted) return;
        final Future<void> f = _startupTasks
            .runCriticalInit(configureDI: configureDI, timeline: timeline)
            .catchError((Object e, StackTrace stackTrace) {
              logger.e('Critical init failed: $e', stackTrace: stackTrace);
            });
        criticalInitFutureCompleter.complete(f);
      }

      // Preferred path: start right after the first frame paints the splash.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        kickOffCriticalInit();
      });

      timeline.logTotal('=== TOTAL before runApp');
      run(
        _startupTasks.buildBootGate(() async {
          // Widget-side hook: wait for whoever kicks off init first.
          kickOffCriticalInit();
          await criticalInitFutureCompleter.future.then((f) => f);
        }),
      );
      timeline.logTotal('runApp called at');

      // Fallback for environments where no frame pumps (e.g. unit tests): if
      // the post-frame callback hasn't fired after a short wait, start init
      // directly so bootstrap() still makes forward progress.
      if (!criticalInitFutureCompleter.isCompleted) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        kickOffCriticalInit();
      }

      // Await critical init so callers (e.g. tests) observe the same lifecycle
      // they did pre-refactor. runApp has already been called, so first pixels
      // ship independently of this await.
      await criticalInitFutureCompleter.future.then((f) => f);

      if (!AppStartupTasks.skipNonCriticalServicesForTesting) {
        _startupTasks.initializeNonCriticalServices();
      }
    } catch (e, stackTrace) {
      logger.f('CATASTROPHIC ERROR in bootstrap(): $e', stackTrace: stackTrace);
      run(_startupTasks.buildFatalErrorApp());
    }
  }
}

class AppStartupTasks {
  AppStartupTasks();

  static bool skipNonCriticalServicesForTesting = false;

  static const Duration _nonCriticalStartupDelay = Duration(milliseconds: 3200);
  static const Duration _notificationLaunchProbeTimeout = Duration(
    milliseconds: 180,
  );
  static const Duration _notificationPermissionSoftTimeout = Duration(
    milliseconds: 1500,
  );
  static const Duration _notificationPermissionDeferredDelay = Duration(
    seconds: 3,
  );
  static const Duration _notificationChannelDeferredDelay = Duration(
    seconds: 5,
  );

  static const Duration _quranAssetsPrefetchDelay = Duration(milliseconds: 400);

  QuranAssetsPrefetchService? _quranAssetsPrefetchService;
  QuranAssetsPrefetchPolicyService? _quranAssetsPrefetchPolicyService;

  Future<void>? _notificationServiceInitFuture;
  Future<void>? _notificationHandlersInitFuture;
  Future<void>? _crashlyticsInitFuture;
  Future<void>? _analyticsInitFuture;
  Future<void>? _notificationPermissionFuture;

  void resetLaunchState() {
    AppRouter.disableStateRestoration = false;
    AppRouter.pendingStartupNotificationLaunch = false;
    AppRouter.pendingFcmMessage = null;
    AppRouter.pendingLocalNotificationResponse = null;
    AppRouter.lastProcessedNotificationId = null;
  }

  /// Clears memoized init futures. Tests re-stub getIt between cases and need
  /// the one-shot helpers below to actually run each time. Not intended for
  /// runtime use.
  @visibleForTesting
  void resetMemoizedInitFutures() {
    _notificationServiceInitFuture = null;
    _notificationHandlersInitFuture = null;
    _crashlyticsInitFuture = null;
    _analyticsInitFuture = null;
    _notificationPermissionFuture = null;
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Runs the critical init pipeline that used to live pre-runApp. Order is
  /// important: Firebase must be ready before DI (which registers Firebase*
  /// singletons), and HydratedStorage must be ready before any HydratedBloc
  /// is constructed (which happens when AppProviders mount).
  Future<void> runCriticalInit({
    required DiConfigurator configureDI,
    required LaunchTimeline timeline,
  }) async {
    bool firebaseOk = false;
    timeline.resetPhase();

    final Future<void> firebaseFuture = initializeFirebase()
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

    // HydratedStorage is independent of Firebase; run in parallel.
    final Future<void> hydratedFuture = initializeHydratedStorage()
        .then((_) => timeline.log('HydratedStorage'))
        .catchError((Object e) => timeline.log('HydratedStorage FAILED'));

    await Future.wait([firebaseFuture, hydratedFuture]);
    timeline.log('Critical parallel (firebase+hydrated)');

    if (firebaseOk) {
      try {
        timeline.resetPhase();
        await configureForegroundMessaging();
        timeline.log('FCM setup');
      } catch (e) {
        logger.d('[LaunchApp] FCM setup FAILED: $e');
      }
    } else {
      AppRouter.init();
    }

    timeline.resetPhase();
    QuranQcfLocator.setup();
    timeline.log('DI quranQcfLocator');

    timeline.resetPhase();
    await configureDI();
    timeline.log('DI configureDependencies');

    timeline.resetPhase();
    await QuranImageDependenciesModule.initialize();
    timeline.log('DI quran_image dependencies');

    initializeBlocObserver();

    // Notification probe and SystemChrome don't block provider mount but we
    // want them done before the first route renders so splash sees correct
    // overlay style + launch notification state.
    timeline.resetPhase();
    final Future<void> notificationFuture = prepareNotificationLaunchState()
        .then((_) => timeline.log('NotificationDispatcher'))
        .catchError(
          (Object e) => timeline.log('NotificationDispatcher FAILED'),
        );

    final Future<void> chromeFuture = configureSystemChrome()
        .then((_) => timeline.log('SystemChrome'))
        .catchError((Object e) => timeline.log('SystemChrome FAILED/timeout'));

    await Future.wait([notificationFuture, chromeFuture]);
    timeline.log('Critical parallel (notif+chrome)');
    timeline.logTotal('=== Critical init done');
  }

  /// Root widget that shows the native-matching splash until
  /// [startCriticalInit] resolves, then swaps in the real app. The gate calls
  /// [startCriticalInit] from a postFrameCallback so the splash paints its
  /// first frame BEFORE the (synchronous, isolate-saturating) init work
  /// begins. This trades ~16ms of "splash appears later" for eliminating the
  /// ~700ms vsync wait we'd otherwise see on frame #1.
  Widget buildBootGate(Future<void> Function() startCriticalInit) {
    return _BootGate(
      startCriticalInit: startCriticalInit,
      child: buildRootApp(),
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
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
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
    if (AppStartupTasks.skipNonCriticalServicesForTesting) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future<void>.delayed(
          AppStartupTasks.skipNonCriticalServicesForTesting
              ? Duration.zero
              : _nonCriticalStartupDelay,
          () {
            return _initializeNonCriticalServicesInBackground();
          },
        ),
      );
    });
  }

  Future<void> _initializeNonCriticalServicesInBackground() async {
    final LaunchTimeline timeline = LaunchTimeline()..startPhase();

    // Defer Android notification channel creation well past first interactive
    // frames to avoid startup frame contention.
    unawaited(_createNotificationChannelDeferred());

    // Keep crash reporting out of cold-start critical path.
    unawaited(initializeCrashlytics());

    // Staggered initialization to prevent main thread starvation
    // on mid-range devices like OPPO A98.

    try {
      await initializeHive();
      timeline.log('Phase0 hive');
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.d('[LaunchApp] Phase0 error: $e');
    }

    try {
      timeline.resetPhase();
      // Parallelize independent startup tasks to reduce sequential blocking.
      // Small 100ms staggering prevents massive platform channel congestion.
      await Future.wait([
        initializeCredentialManager(),
        Future<void>.delayed(
          const Duration(milliseconds: 100),
        ).then((_) => initializeAnalytics()),
      ]);

      timeline.log('Phase1 (credential+analytics)');
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.d('[LaunchApp] Phase1 error: $e');
    }

    try {
      timeline.resetPhase();
      await Future.wait([
        initializeNotificationService(),
        initializeAthkarNotifications(),
        initializeDownloads(),
      ]);
      timeline.log('Phase3 notificationService+athkar+downloads');

      timeline.resetPhase();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await initializeAudioService();
      timeline.log('Phase3 audioService');

      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.d('[LaunchApp] Phase3 error: $e');
    }

    try {
      timeline.resetPhase();
      await quranQcfLocator<MushafService>().ensureLoaded();
      timeline.log('Phase4 quranData');

      unawaited(_prefetchQuranAssetsDeferred());
      timeline.log('Phase4 quranAssetsPrefetch scheduled');

      // Stagger second wave of background data
      await Future<void>.delayed(const Duration(milliseconds: 200));

      timeline.resetPhase();
      await initializeFirebaseDataAsync();
      timeline.log('Phase4 firebaseData');

      // Keep permission probing away from first-route interaction frames.
      timeline.resetPhase();
      await Future<void>.delayed(
        AppStartupTasks.skipNonCriticalServicesForTesting
            ? Duration.zero
            : _notificationPermissionDeferredDelay,
      );
      await requestNotificationPermission();
      timeline.log('Phase5 notificationPermission');
    } catch (e) {
      logger.d('[LaunchApp] Phase4 error: $e');
    }

    logger.d('[LaunchApp] === All non-critical services done ===');
  }

  Future<void> _prefetchQuranAssetsDeferred() async {
    try {
      await Future<void>.delayed(_quranAssetsPrefetchDelay);
      await _assetPrefetchService.prefetchInBackground();
    } catch (e) {
      logger.d('[LaunchApp] Quran asset prefetch skipped/failed: $e');
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

  Future<void> initializeNotificationService() async {
    return _notificationServiceInitFuture ??= () async {
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
    }();
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
      logger.d(
        'Warning: Could not initialize HydratedStorage, using in-memory fallback: $e',
      );
      HydratedBloc.storage = _InMemoryStorage();
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
    return _crashlyticsInitFuture ??= () async {
      try {
        final CrashlyticsService crashlyticsService =
            getIt<CrashlyticsService>();
        await crashlyticsService.initialize();
      } catch (e) {
        logger.d('Crashlytics initialization error: $e');
      }
    }();
  }

  Future<void> initializeAnalytics() async {
    return _analyticsInitFuture ??= () async {
      try {
        final AnalyticsInitializationService analyticsInitService =
            getIt<AnalyticsInitializationService>();
        await analyticsInitService.initialize();
      } catch (e) {
        logger.d('Analytics initialization error: $e');
      }
    }();
  }

  Future<void> requestNotificationPermission() async {
    return _notificationPermissionFuture ??= () async {
      try {
        final NotificationPermissionService notificationPermissionService =
            getIt<NotificationPermissionService>();
        await notificationPermissionService
            .requestPermissionIfNecessary()
            .timeout(
              _notificationPermissionSoftTimeout,
              onTimeout: () {
                logger.d(
                  'Notification permission request still pending (deferred)',
                );
              },
            );
        logger.d('Notification permission request completed');
      } catch (e) {
        logger.d('Warning: Could not request notification permission: $e');
      }
    }();
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
      // Keep pre-runApp on a fast path: only probe FCM cold-start payload.
      // Local notification launch probing is deferred until after first frame.
      final RemoteMessage? fcmInitialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(_notificationLaunchProbeTimeout, onTimeout: () => null);

      if (fcmInitialMessage != null) {
        AppRouter.disableStateRestoration = true;
        AppRouter.pendingStartupNotificationLaunch = true;
        AppRouter.pendingFcmMessage = fcmInitialMessage;
      }

      logger.d('Notification launch state prepared (fcm-only)');
    } catch (e) {
      logger.d('Warning: Could not prepare notification launch state: $e');
    }
  }

  Future<void> initializeNotificationHandlers() async {
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

        final IDownloadNotificationService downloadNotificationService =
            getIt<IDownloadNotificationService>();
        await downloadNotificationService.initialize();

        logger.d('Notification handlers initialized');
      } catch (e) {
        logger.d('Warning: Could not initialize notification handlers: $e');
      }
    }();
  }

  Future<void> _createNotificationChannelDeferred() async {
    try {
      await Future<void>.delayed(
        AppStartupTasks.skipNonCriticalServicesForTesting
            ? Duration.zero
            : _notificationChannelDeferredDelay,
      );
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      await dispatcher.initialize();
      logger.d('Deferred notification channel ensured');
    } catch (e) {
      logger.d('Warning: Could not create deferred notification channel: $e');
    }
  }

  Future<void> initializeAudioService() async {
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

/// Root widget that shows a native-matching launch splash until
/// [criticalInit] resolves, then swaps in [child]. This lets us call runApp()
/// immediately after WidgetsFlutterBinding.ensureInitialized(), so pre-runApp
/// time is near zero and the user sees pixels sooner.
class _BootGate extends StatefulWidget {
  const _BootGate({required this.startCriticalInit, required this.child});

  final Future<void> Function() startCriticalInit;
  final Widget child;

  @override
  State<_BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<_BootGate> {
  static const Color _launchBackgroundColor = Color(0xFF1AADC5);
  static const String _launchWordmarkAsset =
      'assets/images/launch_wordmark.png';
  static const double _wordmarkBoxSize = 288;
  static const SystemUiOverlayStyle _launchOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: _launchBackgroundColor,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: _launchBackgroundColor,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Bootstrap() schedules critical init from its own post-frame callback;
    // here we just await the resulting future so we can swap in the real app
    // when it completes. Calling startCriticalInit() is a no-op if bootstrap
    // already kicked it off, which it will have in production.
    widget.startCriticalInit().whenComplete(() {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return const _LaunchSplash(
      backgroundColor: _launchBackgroundColor,
      overlayStyle: _launchOverlayStyle,
      wordmarkAsset: _launchWordmarkAsset,
      wordmarkBoxSize: _wordmarkBoxSize,
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash({
    required this.backgroundColor,
    required this.overlayStyle,
    required this.wordmarkAsset,
    required this.wordmarkBoxSize,
  });

  final Color backgroundColor;
  final SystemUiOverlayStyle overlayStyle;
  final String wordmarkAsset;
  final double wordmarkBoxSize;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: backgroundColor,
          child: SizedBox.expand(
            child: Center(
              child: SizedBox.square(
                dimension: wordmarkBoxSize,
                child: Image.asset(
                  wordmarkAsset,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      ),
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
