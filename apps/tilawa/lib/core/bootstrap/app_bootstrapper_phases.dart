part of 'app_startup.dart';

/// Extension methods for AppBootstrapper that handle the bootstrap coordination logic.
/// These helpers are extracted to improve readability while keeping the main bootstrap
/// flow easy to follow.
extension AppBootstrapperPhases on AppBootstrapper {
  /// Runs the main bootstrap phases: binding setup, coordinator creation,
  /// runApp execution, and critical init completion.
  Future<void> runBootstrapPhases({
    required AppRunner run,
    required DiConfigurator configureDI,
    required LaunchTimeline timeline,
  }) async {
    logger.d(
      '[AppLaunch][AppBootstrapperPhases.runBootstrapPhases]: Start in (${DateTime.now()})',
    );
    timeline.startPhase();
    WidgetsFlutterBinding.ensureInitialized();
    if (_startupTasks.launchConfig.frameWatcher) {
      PerfLogger.startFrameWatcher();
    }
    if (_startupTasks.launchConfig.resetLaunchState) {
      _startupTasks.resetLaunchState();
    }
    timeline.log('WidgetsBinding');

    final CriticalInitCoordinator coordinator = createCriticalInitCoordinator(
      configureDI: configureDI,
      timeline: timeline,
    );

    scheduleCriticalInit(coordinator);

    timeline.logTotal('=== TOTAL before runApp');
    run(_startupTasks.buildBootGate(coordinator.initAction));
    timeline.logTotal('runApp called at');

    await ensureCriticalInitCompletes(coordinator);

    if (!AppStartupTasks.skipNonCriticalServicesForTesting &&
        _startupTasks.launchConfig.nonCriticalServices) {
      _startupTasks.initializeNonCriticalServices();
    }
  }

  /// Creates a coordinator that manages the critical initialization lifecycle.
  CriticalInitCoordinator createCriticalInitCoordinator({
    required DiConfigurator configureDI,
    required LaunchTimeline timeline,
  }) {
    logger.d(
      '[AppLaunch][AppBootstrapperPhases.createCriticalInitCoordinator]: Start in (${DateTime.now()})',
    );
    final Completer<Future<void>> completer = Completer<Future<void>>();

    void kickOff() {
      if (completer.isCompleted) return;
      final Future<void> f = _startupTasks
          .runCriticalInit(configureDI: configureDI, timeline: timeline)
          .catchError((Object e, StackTrace stackTrace) {
            logger.e('Critical init failed: $e', stackTrace: stackTrace);
          });
      completer.complete(f);
    }

    Future<void> initAction() async {
      kickOff();
      await completer.future.then((f) => f);
    }

    return CriticalInitCoordinator(
      kickOff: kickOff,
      initAction: initAction,
      completer: completer,
    );
  }

  /// Schedules critical init to start after the first frame paints.
  void scheduleCriticalInit(CriticalInitCoordinator coordinator) {
    logger.d(
      '[AppLaunch][AppBootstrapperPhases.scheduleCriticalInit]: Start in (${DateTime.now()})',
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      coordinator.kickOff();
    });
  }

  /// Ensures critical init completes, with fallback for test environments.
  Future<void> ensureCriticalInitCompletes(
    CriticalInitCoordinator coordinator,
  ) async {
    logger.d(
      '[AppLaunch][AppBootstrapperPhases.ensureCriticalInitCompletes]: Start in (${DateTime.now()})',
    );
    if (!coordinator.completer.isCompleted) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      coordinator.kickOff();
    }
    await coordinator.completer.future.then((f) => f);
  }
}
