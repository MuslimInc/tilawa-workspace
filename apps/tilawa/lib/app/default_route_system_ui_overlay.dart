import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../core/bootstrap/first_frame_log.dart';
import '../core/bootstrap/splash_launch_handoff.dart';
import '../core/telemetry/startup_perf_log.dart';
import '../router/app_router.dart';
import '../router/shell_route_location.dart';
import '../shared/widgets/quran_player_chrome.dart';

/// Applies the route-driven [SystemUiOverlayStyle] for the whole app.
///
/// Lives in [MaterialApp.router]'s `builder` so every route shares one
/// [AnnotatedRegion] and one imperative [SystemChrome] apply path. The
/// optional constructor parameters are test seams; production uses the
/// [AppRouter] / [SplashLaunchHandoff] defaults.
class DefaultRouteSystemUiOverlay extends StatefulWidget {
  const DefaultRouteSystemUiOverlay({
    super.key,
    required this.child,
    this.routeChanges,
    this.currentRoutePath,
    this.splashRouteHasPainted,
    this.markSplashRoutePainted,
  });

  final Widget? child;

  /// Notifies when the active route changes.
  ///
  /// Defaults to [AppRouter]'s router delegate.
  final Listenable? routeChanges;

  /// Returns the active route path used to pick the overlay style.
  ///
  /// Defaults to [AppRouter]'s current state.
  final ValueGetter<String>? currentRoutePath;

  /// Whether the routed app has painted its first frame.
  ///
  /// Defaults to [SplashLaunchHandoff.splashRouteHasPainted].
  final ValueListenable<bool>? splashRouteHasPainted;

  /// Marks the routed first frame as painted.
  ///
  /// Defaults to [SplashLaunchHandoff.markSplashRoutePainted].
  final VoidCallback? markSplashRoutePainted;

  @override
  State<DefaultRouteSystemUiOverlay> createState() =>
      _DefaultRouteSystemUiOverlayState();
}

class _DefaultRouteSystemUiOverlayState
    extends State<DefaultRouteSystemUiOverlay>
    with WidgetsBindingObserver {
  SystemUiOverlayStyle? _lastAppliedStyle;
  bool _launchHandoffScheduled = false;
  bool _loggedFirstBuild = false;
  bool _chromeRefreshScheduled = false;

  static final SystemUiOverlayStyle _launchSplashOverlayStyle =
      AppSystemChromeStyle.buildColoredScreenStyle(
        backgroundColor: AppColors.launchSplashBackground,
      );

  Listenable get _routeChanges =>
      widget.routeChanges ?? AppRouter.router.routerDelegate;

  ValueListenable<bool> get _splashRouteHasPainted =>
      widget.splashRouteHasPainted ?? SplashLaunchHandoff.splashRouteHasPainted;

  VoidCallback get _markSplashRoutePainted =>
      widget.markSplashRoutePainted ??
      SplashLaunchHandoff.markSplashRoutePainted;

  String get _currentRoutePath {
    final ValueGetter<String>? override = widget.currentRoutePath;
    if (override != null) {
      return override();
    }
    // [GoRouter.state] throws StateError while matches are unresolved (e.g.
    // Android resume after saveInstanceState). ShellRouteLocation reads
    // [RouteMatchList] defensively — same pattern as [AppRouter._currentLocation].
    return ShellRouteLocation.activeMatchedLocation();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _splashRouteHasPainted.addListener(_scheduleChromeRefresh);
    _routeChanges.addListener(_scheduleChromeRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleLaunchHandoffMark();
      }
    });
  }

  @override
  void dispose() {
    _splashRouteHasPainted.removeListener(_scheduleChromeRefresh);
    _routeChanges.removeListener(_scheduleChromeRefresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    // Root back gesture on Android 12+ moves the task to back without
    // destroying the activity. On a fast relaunch the window's system-bar
    // appearance has been reset to NormalTheme (light status icons), but
    // [SystemChrome] still caches the last style it sent and dedupes any
    // identical re-apply — so the bars stay broken until a route with a
    // *different* style (e.g. the Quran reader) happens to be visited.
    // Clear both caches the way the framework does on engine detach, then
    // re-apply so the current style actually reaches the platform.
    SystemChrome.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    _lastAppliedStyle = null;
    _scheduleChromeRefresh();
  }

  /// Refreshes [SystemChrome] and [AnnotatedRegion] after the frame.
  ///
  /// Never call [setState] or [SystemChrome.setSystemUIOverlayStyle] from
  /// [build] — GoRouter can notify [routerDelegate] while the child mounts,
  /// which previously rebuilt [ListenableBuilder] mid-build (`!_dirty`).
  void _scheduleChromeRefresh() {
    if (!mounted || _chromeRefreshScheduled) {
      return;
    }
    _chromeRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chromeRefreshScheduled = false;
      if (!mounted) {
        return;
      }
      final bool styleChanged = _applySystemUiOverlay();
      if (styleChanged) {
        setState(() {});
      }
    });
    // A post-frame callback alone does not request a frame; without this the
    // refresh would wait for the next unrelated rebuild when the app is idle.
    WidgetsBinding.instance.scheduleFrame();
  }

  SystemUiOverlayStyle _overlayStyleForRoute(ThemeData theme) {
    final String path = _currentRoutePath;
    final Color? playerNavOverride = context
        .read<QuranPlayerChromeNotifier>()
        .systemNavigationBarColorOverride;

    return switch (path) {
      '/splash' => AppSystemChromeStyle.buildColoredScreenStyle(
        backgroundColor: AppColors.launchSplashBackground,
      ),
      '/login' => AppSystemChromeStyle.buildColoredScreenStyle(
        backgroundColor: theme.colorScheme.primary,
      ),
      '/language-welcome' ||
      '/onboarding' => AppSystemChromeStyle.buildDefaultAppStyle(
        theme,
        statusBarBackgroundColor: theme.scaffoldBackgroundColor,
        navigationBarColor: theme.scaffoldBackgroundColor,
      ),
      _ => AppSystemChromeStyle.buildDefaultAppStyle(
        theme,
        statusBarBackgroundColor: theme.scaffoldBackgroundColor,
        navigationBarColor:
            playerNavOverride ??
            theme.componentTokens.adaptiveShell.bottomNavBackgroundColor,
      ),
    };
  }

  /// Returns true when the overlay style changed.
  bool _applySystemUiOverlay() {
    if (!_splashRouteHasPainted.value) {
      return false;
    }
    final theme = Theme.of(context);
    final overlayStyle = _overlayStyleForRoute(theme);
    if (_lastAppliedStyle == overlayStyle) {
      return false;
    }
    _lastAppliedStyle = overlayStyle;
    AppSystemChromeStyle.updateDefaultAppStyle(overlayStyle);
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    return true;
  }

  SystemUiOverlayStyle _overlayStyleForBuild(BuildContext context) {
    if (!_splashRouteHasPainted.value) {
      return _launchSplashOverlayStyle;
    }
    return _overlayStyleForRoute(Theme.of(context));
  }

  void _scheduleLaunchHandoffMark() {
    if (_launchHandoffScheduled ||
        widget.child == null ||
        _splashRouteHasPainted.value) {
      return;
    }
    _launchHandoffScheduled = true;
    firstFrameLog('TilawaApp scheduling routed first-frame handoff mark');
    StartupPerfLog.log('routed_handoff_mark_scheduled');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _launchHandoffScheduled = false;
      if (!mounted || widget.child == null || _splashRouteHasPainted.value) {
        firstFrameLog(
          'TilawaApp handoff mark skipped '
          '(mounted=$mounted hasChild=${widget.child != null} '
          'painted=${_splashRouteHasPainted.value})',
        );
        StartupPerfLog.log(
          'routed_handoff_mark_skipped',
          detail:
              'mounted=$mounted hasChild=${widget.child != null} '
              'painted=${_splashRouteHasPainted.value}',
        );
        return;
      }
      firstFrameLog('TilawaApp routed first post-frame → mark handoff');
      StartupPerfLog.log('routed_handoff_mark_fired');
      _markSplashRoutePainted();
      // Apply immediately so Android drops launch-theme light icons before the
      // next frame (NormalTheme no longer forces windowLightStatusBar=false).
      if (_applySystemUiOverlay()) {
        setState(() {});
      } else {
        _scheduleChromeRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<QuranPlayerChromeNotifier>();
    if (!_loggedFirstBuild) {
      _loggedFirstBuild = true;
      firstFrameLog('TilawaApp DefaultRouteSystemUiOverlay first build');
      StartupPerfLog.log('default_route_overlay_first_build');
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyleForBuild(context),
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
