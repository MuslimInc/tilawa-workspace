part of 'app_startup.dart';

/// Extension methods for AppStartupTasks that handle the critical
/// initialization phases. These methods are extracted to improve readability
/// and maintainability while preserving the exact execution order.
extension AppStartupCriticalPhases on AppStartupTasks {
  /// Phase 1: Initialize Firebase and HydratedStorage in parallel.
  /// Returns true if Firebase initialized successfully.
  Future<bool> initializeFirebaseAndHydratedStorage(
    LaunchTimeline timeline,
  ) async {
    logger.d(
      '[AppLaunch] source=AppStartupCriticalPhases.initializeFirebaseAndHydratedStorage: Start in (${DateTime.now()})',
    );
    bool firebaseOk = false;
    timeline.resetPhase();

    final Future<void> firebaseFuture = launchConfig.firebaseInit
        ? initializeFirebase()
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
                unawaited(
                  StartupTelemetry.failure(
                    'firebase_init_failed',
                    e,
                    stackTrace,
                    phase: 'firebase_init',
                  ),
                );
              })
        : Future<void>.value();

    // HydratedStorage is independent of Firebase; run in parallel.
    final Future<void> hydratedFuture = launchConfig.hydratedStorageInit
        ? initializeHydratedStorage()
              .then((_) => timeline.log('HydratedStorage'))
              .catchError((Object e) => timeline.log('HydratedStorage FAILED'))
        : Future<void>.value();

    await Future.wait([firebaseFuture, hydratedFuture]);
    timeline.log('Critical parallel (firebase+hydrated)');
    return firebaseOk;
  }

  /// Phase 2: Configure FCM if Firebase is available, otherwise init router.
  Future<void> configurePostFirebaseServices({
    required bool firebaseOk,
    required LaunchTimeline timeline,
  }) async {
    logger.d(
      '[AppLaunch] source=AppStartupCriticalPhases.configurePostFirebaseServices: Start in (${DateTime.now()})',
    );
    if (firebaseOk && launchConfig.foregroundMessaging) {
      try {
        timeline.resetPhase();
        await configureForegroundMessaging();
        timeline.log('FCM setup');
      } catch (e) {
        logger.d(
          '[AppLaunch] source=AppStartupCriticalPhases.configurePostFirebaseServices: FCM setup FAILED at (${DateTime.now()}): $e',
        );
      }
    } else {
      AppRouter.init();
    }
  }

  /// Phase 3: Run all dependency injection configuration.
  Future<void> runDependencyInjection({
    required DiConfigurator configureDI,
    required LaunchTimeline timeline,
  }) async {
    logger.d(
      '[AppLaunch] source=AppStartupCriticalPhases.runDependencyInjection: Start in (${DateTime.now()})',
    );
    timeline.resetPhase();
    QuranQcfLocator.setup();
    timeline.log('DI quranQcfLocator');

    timeline.resetPhase();
    await configureDI(launchConfig: launchConfig);
    timeline.log('DI configureDependencies');

    timeline.resetPhase();
    await QuranImageDependenciesModule.initialize();
    timeline.log('DI quran_image dependencies');

    initializeBlocObserver();
  }

  /// Phase 4: Configure services that must complete before first route renders.
  Future<void> configurePreRenderServices({
    required LaunchTimeline timeline,
  }) async {
    logger.d(
      '[AppLaunch] source=AppStartupCriticalPhases.configurePreRenderServices: Start in (${DateTime.now()})',
    );
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
  }
}

/// Extension methods for AppStartupTasks that handle the non-critical
/// background service initialization phases.
extension AppStartupBackgroundPhases on AppStartupTasks {
  /// Phase 0: Initialize Hive with stagger delay.
  Future<void> runPhase0Hive(LaunchTimeline timeline) async {
    logger.d(
      '[AppLaunch] source=AppStartupBackgroundPhases.runPhase0Hive: Start in (${DateTime.now()})',
    );
    try {
      if (launchConfig.hiveInit) {
        await initializeHive();
        timeline.log('Phase0 hive');
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupBackgroundPhases.runPhase0Hive: Phase0 error at (${DateTime.now()}): $e',
      );
    }
  }

  /// Phase 1: Initialize analytics.
  Future<void> runPhase1Analytics(LaunchTimeline timeline) async {
    logger.d(
      '[AppLaunch] source=AppStartupBackgroundPhases.runPhase1Analytics: Start in (${DateTime.now()})',
    );
    try {
      timeline.resetPhase();
      if (launchConfig.analyticsInit) {
        await initializeAnalytics();
      }

      timeline.log('Phase1 (analytics)');
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupBackgroundPhases.runPhase1Analytics: Phase1 error at (${DateTime.now()}): $e',
      );
    }
  }

  /// Phase 3: Initialize notifications, athkar, downloads, and audio service.
  Future<void> runPhase3NotificationsAndAudio(LaunchTimeline timeline) async {
    logger.d(
      '[AppLaunch] source=AppStartupBackgroundPhases.runPhase3NotificationsAndAudio: Start in (${DateTime.now()})',
    );
    try {
      timeline.resetPhase();
      final List<Future<void>> tasks = <Future<void>>[];
      if (launchConfig.notificationServiceInit) {
        tasks.add(initializeNotificationService());
      }
      if (launchConfig.athkarNotificationsInit) {
        tasks.add(initializeAthkarNotifications());
      }
      if (launchConfig.prayerNotificationsInit) {
        tasks.add(initializePrayerNotifications());
      }
      if (launchConfig.downloadsInit) {
        tasks.add(initializeDownloads());
      }
      // Ayah widget snapshot (spec 041) — guards itself (Android + daily dedup).
      tasks.add(initializeIslamicWidgets());
      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }
      timeline.log('Phase3 notificationService+athkar+prayer+downloads');

      timeline.resetPhase();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (launchConfig.audioServiceInit) {
        await initializeAudioService();
        timeline.log('Phase3 audioService');
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      logger.d(
        '[AppLaunch] source=AppStartupBackgroundPhases.runPhase3NotificationsAndAudio: Phase3 error at (${DateTime.now()}): $e',
      );
    }
  }
}
