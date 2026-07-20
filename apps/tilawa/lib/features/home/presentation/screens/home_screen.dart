import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_route_display.dart';
import 'package:tilawa/features/home/debug/home_skeleton_debug.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/shell/application/shell_tab_reselect.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_reselect_listener.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import '../models/home_dashboard_ui_state.dart';
import '../services/home_dashboard_refresh_error_message.dart';
import '../widgets/home_dashboard_body.dart';
import '../widgets/home_dashboard_content_sliver.dart';
import '../widgets/home_learning_entry.dart';
import '../widgets/home_next_prayer_time.dart';
import '../widgets/home_screen_background.dart';

/// Main daily dashboard for the app shell.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  static const double _heroSnapThresholdFactor = 0.35;
  static const double _heroSnapTolerance = 0.5;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<NestedScrollViewState> _nestedScrollKey =
      GlobalKey<NestedScrollViewState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDashboardLoad());
  }

  void _startDashboardLoad() {
    if (!mounted) {
      return;
    }
    final HomeDashboardBloc bloc = context.read<HomeDashboardBloc>();
    if (bloc.state is! HomeDashboardInitial) {
      return;
    }
    bloc.add(
      HomeDashboardStarted(
        localeIdentifier: Localizations.localeOf(context).languageCode,
      ),
    );
  }

  Future<void> _refreshHome() async {
    final String locale = Localizations.localeOf(context).languageCode;
    final HomeDashboardBloc bloc = context.read<HomeDashboardBloc>();
    final HomeListeningResumeCubit listeningResumeCubit = context
        .read<HomeListeningResumeCubit>();

    await Future.wait([
      bloc.refreshAndWait(localeIdentifier: locale),
      listeningResumeCubit.load(),
    ]);
  }

  Future<void> _scrollToTopOrRefresh() async {
    final NestedScrollViewState? nested = _nestedScrollKey.currentState;
    if (nested == null) {
      await _refreshHome();
      return;
    }

    final ScrollController outer = nested.outerController;
    final ScrollController inner = nested.innerController;
    const double threshold = ShellTabReselect.scrollTopThreshold;
    final bool scrolledDown =
        (outer.hasClients && outer.offset > threshold) ||
        (inner.hasClients && inner.offset > threshold);

    if (!scrolledDown) {
      await _refreshHome();
      return;
    }

    final Duration duration = context.tokens.durationFast;
    const Curve curve = Curves.easeOutCubic;
    await Future.wait<void>([
      if (outer.hasClients)
        outer.animateTo(0, duration: duration, curve: curve),
      if (inner.hasClients)
        inner.animateTo(0, duration: duration, curve: curve),
    ]);
  }

  void _onShellTabReselect() {
    unawaited(_scrollToTopOrRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color canvasBottom =
        theme.componentTokens.homeScreen.backgroundGradientEnd;
    final double topInset = MediaQuery.paddingOf(context).top;

    return _HomeTtfdScope(
      child: ShellTabReselectListener(
        tabIndex: 0,
        onReselect: _onShellTabReselect,
        child: BlocListener<HomeDashboardBloc, HomeDashboardState>(
          listenWhen:
              (HomeDashboardState previous, HomeDashboardState current) {
                return current is HomeDashboardLoaded &&
                    current.refreshError != null &&
                    (previous is! HomeDashboardLoaded ||
                        previous.refreshError != current.refreshError);
              },
          listener: (BuildContext context, HomeDashboardState state) {
            if (state is! HomeDashboardLoaded || state.refreshError == null) {
              return;
            }

            final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
              context,
            );
            if (messenger == null) {
              return;
            }

            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  homeDashboardRefreshErrorMessage(
                    context,
                    state.refreshError!,
                  ),
                ),
              ),
            );
          },
          child: TilawaShellChildScaffold(
            backgroundColor: canvasBottom,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(child: HomeScreenBackground()),
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) =>
                        _onScrollNotification(context, notification),
                    // Debug-only review toggle (Settings → Developer → Force
                    // Home skeleton). [HomeSkeletonDebug.isForced] is always
                    // false in release, so this wrapper is inert in production.
                    child: ValueListenableBuilder<bool>(
                      valueListenable: HomeSkeletonDebug.forceSkeleton,
                      builder: (context, _, _) =>
                          BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
                            builder: (context, blocState) {
                              final HomeDashboardState state =
                                  HomeSkeletonDebug.isForced
                                  ? const HomeDashboardLoading()
                                  : blocState;
                              final HomeDashboardUiState ui =
                                  HomeDashboardUiState.from(state);
                              final Widget dashboard = NestedScrollView(
                                key: _nestedScrollKey,
                                headerSliverBuilder:
                                    (BuildContext context, bool _) {
                                      return HomeNextPrayerTime.buildSlivers(
                                        context: context,
                                        state: state,
                                        onOpenPrayer: widget.onOpenPrayer,
                                      );
                                    },
                                body: CustomScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  slivers: [
                                    HomeDashboardContentSliver(
                                      child: AnimatedSwitcher(
                                        duration: context.tokens.durationMedium,
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        layoutBuilder:
                                            (currentChild, previousChildren) {
                                              return Stack(
                                                alignment: AlignmentDirectional
                                                    .topStart,
                                                children: <Widget>[
                                                  ...previousChildren,
                                                  ?currentChild,
                                                ],
                                              );
                                            },
                                        child: HomeDashboardBody(
                                          key: ValueKey<bool>(
                                            ui.showFullSkeleton,
                                          ),
                                          skeleton: ui.showFullSkeleton,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              // Keep scope above [NestedScrollView] for the
                              // whole load cycle so GlobalKey reparent does not
                              // drop Learn providers mid-AnimatedSwitcher.
                              return HomeLearningEntryScope(
                                child: dashboard,
                              );
                            },
                          ),
                    ),
                  ),
                ),
                // Hit-test spacer only — immersive hero paints under the status
                // bar; keep the key for layout tests.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset,
                  child: const IgnorePointer(
                    child: ColoredBox(
                      key: Key('home_status_bar_chrome'),
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _onScrollNotification(
    BuildContext context,
    ScrollNotification notification,
  ) {
    if (notification.depth != 0) {
      return false;
    }

    if (notification is ScrollEndNotification) {
      _settleHomeHero(context, notification);
    }

    return false;
  }

  void _settleHomeHero(
    BuildContext context,
    ScrollEndNotification notification,
  ) {
    final double? snapTarget = _homeHeroSnapTarget(
      context,
      notification.metrics,
    );
    if (snapTarget == null) {
      return;
    }

    final ScrollPosition? position = _scrollPositionFromNotification(
      notification,
    );
    if (position == null || !position.hasPixels) {
      return;
    }

    final double clampedTarget = snapTarget.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((position.pixels - clampedTarget).abs() <=
        HomeScreen._heroSnapTolerance) {
      return;
    }

    _animateHomeHeroSnap(context, position, clampedTarget);
  }

  double? _homeHeroSnapTarget(BuildContext context, ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) {
      return null;
    }

    final double collapseExtent = HomeNextPrayerTime.collapseScrollExtent(
      context,
    );
    final double offset = metrics.pixels;
    if (offset <= 0 || offset >= collapseExtent) {
      return null;
    }

    final double threshold =
        collapseExtent * HomeScreen._heroSnapThresholdFactor;
    return offset < threshold ? 0 : collapseExtent;
  }

  ScrollPosition? _scrollPositionFromNotification(
    ScrollEndNotification notification,
  ) {
    if (notification.metrics is ScrollPosition) {
      return notification.metrics as ScrollPosition;
    }
    return _scrollPositionFrom(notification.context);
  }

  void _animateHomeHeroSnap(
    BuildContext context,
    ScrollPosition position,
    double target,
  ) {
    unawaited(
      position.animateTo(
        target,
        duration: context.tokens.durationFast,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  ScrollPosition? _scrollPositionFrom(BuildContext? context) {
    if (context == null) {
      return null;
    }
    return Scrollable.maybeOf(context)?.position;
  }
}

class _HomeTtfdScope extends StatelessWidget {
  const _HomeTtfdScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MainScreenCubit? shellCubit = _readMainScreenCubit(context);
    final Widget reporter = BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
      builder: (context, dashboardState) {
        final MainScreenState? shellState = shellCubit?.state;
        final bool shellReady =
            shellState == null ||
            (shellState.isShellActivated && shellState.isInitialTabMounted);
        final HomeDashboardState effectiveState = HomeSkeletonDebug.isForced
            ? const HomeDashboardLoading()
            : dashboardState;
        final HomeDashboardUiState ui = HomeDashboardUiState.from(
          effectiveState,
        );
        final bool dashboardReady =
            effectiveState is HomeDashboardLoaded && !ui.showFullSkeleton;

        return TilawaSentryRouteReporter(
          when: dashboardReady && shellReady,
          child: child,
        );
      },
    );

    if (shellCubit == null) {
      return reporter;
    }

    return BlocBuilder<MainScreenCubit, MainScreenState>(
      builder: (context, _) => reporter,
    );
  }

  MainScreenCubit? _readMainScreenCubit(BuildContext context) {
    try {
      return context.read<MainScreenCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
