import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/home/debug/home_skeleton_debug.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/shell/application/shell_tab_reselect.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_reselect_listener.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import '../models/home_dashboard_ui_state.dart';
import '../services/home_dashboard_refresh_error_message.dart';
import '../widgets/home_dashboard_body.dart';
import '../widgets/home_dashboard_content_sliver.dart';
import '../widgets/home_featured_tutor_card.dart';
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
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _onShellTabReselect() {
    unawaited(
      ShellTabReselect.scrollToTopOrRefresh(
        scrollController: _scrollController,
        refresh: _refreshHome,
        duration: context.tokens.durationFast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color canvasBottom =
        theme.componentTokens.homeScreen.backgroundGradientEnd;
    final double topInset = MediaQuery.paddingOf(context).top;

    return ShellTabReselectListener(
      tabIndex: 0,
      onReselect: _onShellTabReselect,
      child: BlocListener<HomeDashboardBloc, HomeDashboardState>(
        listenWhen: (HomeDashboardState previous, HomeDashboardState current) {
          return current is HomeDashboardLoaded &&
              current.refreshErrorMessage != null &&
              (previous is! HomeDashboardLoaded ||
                  previous.refreshErrorMessage != current.refreshErrorMessage);
        },
        listener: (BuildContext context, HomeDashboardState state) {
          if (state is! HomeDashboardLoaded ||
              state.refreshErrorMessage == null) {
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
                  state.refreshErrorMessage!,
                ),
              ),
            ),
          );
        },
        child: Scaffold(
          backgroundColor: canvasBottom,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: HomeScreenBackground()),
              RefreshIndicator.adaptive(
                edgeOffset: topInset,
                displacement: context.tokens.spaceExtraLarge,
                onRefresh: _refreshHome,
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
                            final Widget? tutorHeaderSliver =
                                ui.showFullSkeleton
                                ? null
                                : homeFeaturedTutorCardSliver(context);

                            return CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                ...HomeNextPrayerTime.buildSlivers(
                                  context: context,
                                  state: state,
                                  onOpenPrayer: widget.onOpenPrayer,
                                ),
                                ?tutorHeaderSliver,
                                HomeDashboardContentSliver(
                                  child: AnimatedSwitcher(
                                    duration: context.tokens.durationMedium,
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    layoutBuilder:
                                        (currentChild, previousChildren) {
                                          return Stack(
                                            alignment:
                                                AlignmentDirectional.topStart,
                                            children: <Widget>[
                                              ...previousChildren,
                                              ?currentChild,
                                            ],
                                          );
                                        },
                                    child: HomeDashboardBody(
                                      key: ValueKey<bool>(ui.showFullSkeleton),
                                      skeleton: ui.showFullSkeleton,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                  ),
                ),
              ),
            ],
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

    final double clampedTarget = snapTarget
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
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
