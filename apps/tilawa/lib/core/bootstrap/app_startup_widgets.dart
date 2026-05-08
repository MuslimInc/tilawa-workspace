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
  Widget buildRootApp() {
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
  static const Color _launchBackgroundColor = AppColors.defaultPrimary;
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
