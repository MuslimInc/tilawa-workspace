import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/shell/application/shell_tab_reselect.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_reselect_listener.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
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
  final SliverOverlapAbsorberHandle _tutorHeaderOverlapHandle =
      SliverOverlapAbsorberHandle();

  @override
  void dispose() {
    _tutorHeaderOverlapHandle.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    final String locale = Localizations.localeOf(context).languageCode;
    final listeningResumeCubit = context.read<HomeListeningResumeCubit>();
    context.read<HomeDashboardBloc>().add(
      HomeDashboardRefreshRequested(localeIdentifier: locale),
    );
    await Future.wait([
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
      child: Scaffold(
        backgroundColor: canvasBottom,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: HomeScreenBackground()),
            RefreshIndicator(
              edgeOffset: topInset + kToolbarHeight,
              onRefresh: _refreshHome,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) =>
                    _onScrollNotification(context, notification),
                child: BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
                  builder: (context, state) {
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
                        if (homeFeaturedTutorCardSliver(
                              context,
                              scrollController: _scrollController,
                              pinScrollOffset:
                                  HomeNextPrayerTime.scrollOffsetWhenTutorCardPins(
                                    context,
                                  ),
                            )
                            case final Widget sliver) ...[
                          SliverOverlapAbsorber(
                            handle: _tutorHeaderOverlapHandle,
                            sliver: sliver,
                          ),
                          SliverOverlapInjector(
                            handle: _tutorHeaderOverlapHandle,
                          ),
                        ],
                        HomeDashboardContentSliver(
                          child: const HomeDashboardBody(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
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
