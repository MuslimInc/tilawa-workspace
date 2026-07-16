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
    return SentryConfig.wrapRootWidget(
      _BootGate(
        startCriticalInit: startCriticalInit,
        child: buildRootApp(),
      ),
    );
  }

  /// Builds the root app widget. [DevicePreview] wraps debug/profile builds only
  /// (see [device_preview_app_builder.dart] conditional import).
  Widget buildRootApp() {
    return wrapRootAppWithDevicePreview(const TilawaApp());
  }

  /// Builds the fatal error fallback app when bootstrap fails catastrophically.
  ///
  /// Runs before DI/l10n exist, so strings are hardcoded in both app
  /// languages. Retry re-runs the full bootstrap pipeline ([bootstrap] and
  /// [configureDependencies] are both safe to re-enter).
  Widget buildFatalErrorApp({Future<void> Function()? onRetry}) {
    return SentryConfig.wrapRootWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _StartupFatalErrorScreen(onRetry: onRetry ?? bootstrap),
      ),
    );
  }
}

class _StartupFatalErrorScreen extends StatefulWidget {
  const _StartupFatalErrorScreen({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<_StartupFatalErrorScreen> createState() =>
      _StartupFatalErrorScreenState();
}

class _StartupFatalErrorScreenState extends State<_StartupFatalErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) {
      return;
    }
    setState(() => _retrying = true);
    try {
      // On success runApp replaces this tree; on failure bootstrap()
      // builds a fresh fatal error app, so either way this screen goes away.
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.launchSplashBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.launchSplashForeground.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              const Text(
                'حدث خطأ غير متوقع',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.launchSplashForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.launchSplashForeground.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // The fatal-error app renders before the design-system theme
              // exists (no tokens), so TilawaButton cannot be used here.
              // tilawa-ui-exception: UIKIT-BUTTON-STARTUP-FATAL
              // ignore: tilawa_lints/tilawa_ui_component
              FilledButton(
                onPressed: _retrying ? null : _retry,
                child: _retrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إعادة المحاولة • Retry'),
              ),
            ],
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
  static final SystemUiOverlayStyle _launchOverlayStyle =
      AppSystemChromeStyle.buildColoredScreenStyle(
        backgroundColor: _launchBackground,
      );

  /// Splash-stuck watchdog: comfortably above [AppStartupReadiness]'s 10s
  /// safety net so it only fires for genuinely hung boots, not slow devices.
  static const Duration _bootWatchdogTimeout = Duration(seconds: 20);

  bool _ready = false;
  bool _handoffToAppStarted = false;
  Future<void>? _criticalInitFuture;
  Timer? _bootWatchdogTimer;

  @override
  void initState() {
    super.initState();
    firstFrameLog('BootGate initState');
    StartupPerfLog.log('boot_gate_init');
    unawaited(StartupTelemetry.phase('boot_gate_start'));
    // Listen for severe native trim before TilawaApp mounts (FLUTTER-9).
    AppMemoryPressureHandler.attach();
    firstFrameLog('BootGate critical init scheduling');
    SplashLaunchHandoff.resetForNewLaunch();
    LaunchFirstFrameGate.scheduleReleaseAfterFirstFrame();
    _startBootWatchdog();
    _awaitCriticalInit();
  }

  @override
  void dispose() {
    _bootWatchdogTimer?.cancel();
    super.dispose();
  }

  void _startBootWatchdog() {
    _bootWatchdogTimer = Timer(_bootWatchdogTimeout, () {
      if (!mounted || _ready) {
        return;
      }
      logger.e(
        'BootGate stuck: critical init not complete after '
        '${_bootWatchdogTimeout.inSeconds}s; user is still on launch splash',
      );
      unawaited(
        StartupTelemetry.failure(
          'boot_gate_stuck',
          TimeoutException(
            'critical init incomplete',
            _bootWatchdogTimeout,
          ),
          StackTrace.current,
          phase: 'boot_gate',
        ),
      );
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload rebuilds providers without re-running bootstrap DI.
    if (!isDependencyGraphReady) {
      _ready = false;
      _criticalInitFuture = null;
      _handoffToAppStarted = false;
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
          if (!isDependencyGraphReady) {
            throw StateError(
              'Dependency graph incomplete after critical init '
              '(SettingsCubit missing)',
            );
          }
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
          _bootWatchdogTimer?.cancel();
          StartupPerfLog.log(
            'boot_gate_ready',
            detail: 'target=${plan.target.name} location=${plan.location}',
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
    if (isDependencyGraphReady) {
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
        AppRouter.applyBootLaunchPlan(
          targetLocation: plan.location,
          notificationLocation: plan.location,
          notificationExtra: plan.extra,
          timedOut: plan.timedOut,
        );
      case StartupLaunchTarget.home:
      case StartupLaunchTarget.login:
      case StartupLaunchTarget.onboarding:
        AppRouter.applyBootLaunchPlan(
          targetLocation: plan.location,
          timedOut: plan.timedOut,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedBootGateSplash) {
      _loggedBootGateSplash = true;
      ColdStartNavigationMetrics.recordBootGateSplash();
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_ready) widget.child else const SizedBox.shrink(),
          _LaunchSplashOverlay(
            ready: _ready,
            backgroundColor: _launchBackground,
            overlayStyle: _launchOverlayStyle,
          ),
        ],
      ),
    );
  }
}

/// Listens to [SplashLaunchHandoff] locally so [TilawaApp] does not rebuild
/// when the splash overlay is removed.
class _LaunchSplashOverlay extends StatefulWidget {
  const _LaunchSplashOverlay({
    required this.ready,
    required this.backgroundColor,
    required this.overlayStyle,
  });

  final bool ready;
  final Color backgroundColor;
  final SystemUiOverlayStyle overlayStyle;

  @override
  State<_LaunchSplashOverlay> createState() => _LaunchSplashOverlayState();
}

class _LaunchSplashOverlayState extends State<_LaunchSplashOverlay> {
  bool? _lastLoggedPainted;
  bool? _lastLoggedShowSplash;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SplashLaunchHandoff.splashRouteHasPainted,
      builder: (BuildContext context, bool painted, Widget? _) {
        if (_lastLoggedPainted != painted) {
          _lastLoggedPainted = painted;
          StartupPerfLog.log(
            'splash_route_painted',
            detail: 'painted=$painted ready=${widget.ready}',
          );
        }
        final bool showSplash = !widget.ready || !painted;
        if (_lastLoggedShowSplash != showSplash) {
          _lastLoggedShowSplash = showSplash;
          StartupPerfLog.log(
            'splash_overlay',
            detail: showSplash ? 'visible' : 'removed',
          );
          firstFrameLog(
            'BootGate stack: ready=${widget.ready} painted=$painted '
            'showSplash=$showSplash (splash overlay '
            '${showSplash ? "visible" : "removed"})',
          );
        }
        if (!showSplash) {
          return const SizedBox.shrink();
        }
        return _LaunchSplash(
          backgroundColor: widget.backgroundColor,
          overlayStyle: widget.overlayStyle,
        );
      },
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash({
    required this.backgroundColor,
    required this.overlayStyle,
  });

  static int _paintLogCount = 0;

  final Color backgroundColor;
  final SystemUiOverlayStyle overlayStyle;

  @override
  Widget build(BuildContext context) {
    _paintLogCount++;
    if (_paintLogCount == 1) {
      StartupPerfLog.log('launch_splash_first_paint');
    }
    final String paintLabel = _paintLogCount == 1
        ? 'first paint'
        : 'repaint #$_paintLogCount (often allowFirstFrame; same 288dp box)';
    firstFrameLog(
      '_LaunchSplash $paintLabel logoBox=${LaunchSplashContent.logoBoxSize}dp '
      'asset=${LaunchSplashContent.logoAsset}',
    );
    return LaunchSplashCanvas(
      backgroundColor: backgroundColor,
      overlayStyle: overlayStyle,
      child: const LaunchSplashContent(source: 'BootGate_LaunchSplash'),
    );
  }
}
