part of 'app_startup.dart';

/// Extension methods for AppStartupTasks that handle widget building.
/// These are extracted to improve readability of the main class.
extension AppStartupWidgets on AppStartupTasks {
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

  /// Builds the root app widget with DevicePreview wrapper.
  ///
  /// Release omits [DevicePreview] entirely so no preview store or listeners
  /// ship in store builds.
  Widget buildRootApp() {
    if (kReleaseMode) {
      return const TilawaApp();
    }
    return DevicePreview(
      enabled: false,
      builder: (context) => const TilawaApp(),
    );
  }

  /// Builds the fatal error fallback app when bootstrap fails catastrophically.
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
  bool _loggedBootGateSplash = false;

  static const Color _launchBackground = AppColors.launchSplashBackground;
  static const String _appLogoAsset = 'assets/images/app_logo.png';
  static const double _wordmarkBoxSize = AppColors.launchSplashLogoSize;
  static final SystemUiOverlayStyle _launchOverlayStyle =
      AppSystemChromeStyle.buildColoredScreenStyle(
        backgroundColor: _launchBackground,
      );

  bool _ready = false;
  bool _handoffToAppStarted = false;
  Future<void>? _criticalInitFuture;
  bool? _lastLoggedPainted;
  bool? _lastLoggedShowSplash;

  @override
  void initState() {
    super.initState();
    firstFrameLog('BootGate initState');
    unawaited(StartupTelemetry.phase('boot_gate_start'));
    firstFrameLog('BootGate critical init scheduling');
    SplashLaunchHandoff.resetForNewLaunch();
    LaunchFirstFrameGate.scheduleReleaseAfterFirstFrame();
    _awaitCriticalInit();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload rebuilds providers without re-running bootstrap DI.
    if (!getIt.isRegistered<NetworkInfo>()) {
      _ready = false;
      _awaitCriticalInit();
    }
  }

  void _awaitCriticalInit() {
    if (_ready || _criticalInitFuture != null) {
      return;
    }
    unawaited(StartupTelemetry.phase('boot_gate_init_await'));
    // Bootstrap() schedules critical init from its own post-frame callback;
    // here we just await the resulting future so we can swap in the real app
    // when it completes. Calling startCriticalInit() is a no-op if bootstrap
    // already kicked it off, which it will have in production.
    _criticalInitFuture = widget
        .startCriticalInit()
        .then((_) async {
          await _ensureDependenciesRegistered();
          final StartupLaunchPlan plan = await _resolveStartupLaunchPlan();
          _applyStartupLaunchPlan(plan);
          if (!mounted || _handoffToAppStarted) return;
          _handoffToAppStarted = true;
          firstFrameLog(
            'BootGate critical init done → TilawaApp mounts under splash '
            '(target=${plan.target.name} location=${plan.location})',
          );
          unawaited(
            StartupTelemetry.phase(
              'boot_gate_ready',
              data: <String, Object?>{
                'target': plan.target.name,
                'location': plan.location,
              },
            ),
          );
          setState(() {
            _ready = true;
          });
        })
        .catchError((Object error, StackTrace stackTrace) {
          _criticalInitFuture = null;
          logger.e(
            'Critical init failed; staying on launch splash',
            error: error,
            stackTrace: stackTrace,
          );
          unawaited(
            StartupTelemetry.failure(
              'boot_gate_critical_init_failed',
              error,
              stackTrace,
              phase: 'boot_gate',
            ),
          );
        });
  }

  Future<void> _ensureDependenciesRegistered() async {
    if (getIt.isRegistered<NetworkInfo>()) {
      return;
    }
    // Firebase singletons in DI must not run before initializeApp() completes.
    if (Firebase.apps.isEmpty) {
      return;
    }
    await configureDependencies(launchConfig: appLaunchConfig);
  }

  Future<StartupLaunchPlan> _resolveStartupLaunchPlan() async {
    try {
      if (!getIt.isRegistered<StartupLaunchCoordinator>()) {
        return const StartupLaunchPlan.home();
      }
      return await getIt<StartupLaunchCoordinator>().resolve();
    } catch (error, stackTrace) {
      logger.e(
        'Startup launch resolution failed; falling back to home',
        error: error,
        stackTrace: stackTrace,
      );
      return const StartupLaunchPlan.home();
    }
  }

  void _applyStartupLaunchPlan(StartupLaunchPlan plan) {
    switch (plan.target) {
      case StartupLaunchTarget.notification:
        AppRouter.setPendingColdStartRoute(plan.location, extra: plan.extra);
      case StartupLaunchTarget.home:
      case StartupLaunchTarget.login:
      case StartupLaunchTarget.onboarding:
        AppRouter.clearPendingColdStartRoute();
        AppRouter.pendingStartupNotificationLaunch = false;
        AppRouter.disableStateRestoration = false;
        AppRouter.setInitialLaunchLocation(plan.location);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedBootGateSplash) {
      _loggedBootGateSplash = true;
      ColdStartNavigationMetrics.recordBootGateSplash();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: SplashLaunchHandoff.splashRouteHasPainted,
      builder: (BuildContext context, bool painted, Widget? _) {
        if (_lastLoggedPainted != painted) {
          _lastLoggedPainted = painted;
        }
        final bool showSplash = !_ready || !painted;
        if (_lastLoggedShowSplash != showSplash) {
          _lastLoggedShowSplash = showSplash;
          firstFrameLog(
            'BootGate stack: ready=$_ready painted=$painted '
            'showSplash=$showSplash (splash overlay '
            '${showSplash ? "visible" : "removed"})',
          );
        }
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (_ready) widget.child else const SizedBox.shrink(),
              if (showSplash)
                _LaunchSplash(
                  backgroundColor: _launchBackground,
                  overlayStyle: _launchOverlayStyle,
                  wordmarkAsset: _appLogoAsset,
                  wordmarkBoxSize: _wordmarkBoxSize,
                ),
            ],
          ),
        );
      },
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

  static int _paintLogCount = 0;

  final Color backgroundColor;
  final SystemUiOverlayStyle overlayStyle;
  final String wordmarkAsset;
  final double wordmarkBoxSize;

  @override
  Widget build(BuildContext context) {
    _paintLogCount++;
    final String paintLabel = _paintLogCount == 1
        ? 'first paint'
        : 'repaint #$_paintLogCount (often allowFirstFrame; same 288dp box)';
    firstFrameLog(
      '_LaunchSplash $paintLabel logoBox=${wordmarkBoxSize}dp '
      'asset=$wordmarkAsset',
    );
    return LaunchSplashCanvas(
      backgroundColor: backgroundColor,
      overlayStyle: overlayStyle,
      child: LogoHeightProbe(
        source: 'BootGate_LaunchSplash',
        boxSize: wordmarkBoxSize,
        asset: wordmarkAsset,
        child: Image.asset(
          wordmarkAsset,
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
