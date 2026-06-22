import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import '../widgets/home_dashboard_body.dart';
import '../widgets/home_dashboard_content_sliver.dart';
import '../widgets/home_dashboard_hero_sliver.dart';

/// Main daily dashboard for the app shell.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  static const double _heroSnapThresholdFactor = 0.35;
  static const double _heroSnapTolerance = 0.5;

  @override
  Widget build(BuildContext context) {
    final Color sheetColor = context.scaffoldCanvasColor;
    final double topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: sheetColor,
      body: RefreshIndicator(
        edgeOffset: topInset + kToolbarHeight,
        onRefresh: () async {
          final String locale = Localizations.localeOf(context).languageCode;
          final quranResumeCubit = context.read<HomeQuranResumeCubit>();
          final listeningResumeCubit = context.read<HomeListeningResumeCubit>();
          final athkarCompactCubit = context.read<HomeAthkarCompactCubit>();
          final primaryActionCubit = context.read<HomePrimaryActionCubit>();
          context.read<HomeDashboardBloc>().add(
            HomeDashboardRefreshRequested(localeIdentifier: locale),
          );
          await Future.wait([
            quranResumeCubit.load(),
            listeningResumeCubit.load(),
            athkarCompactCubit.load(),
          ]);
          primaryActionCubit.recompute(
            quran: quranResumeCubit.state,
            listening: listeningResumeCubit.state,
            athkar: athkarCompactCubit.state,
          );
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) =>
              _onScrollNotification(context, notification),
          child: BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
            builder: (context, state) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  ...HomeDashboardHeroSliver.buildSlivers(
                    context: context,
                    state: state,
                    onOpenPrayer: onOpenPrayer,
                  ),
                  HomeDashboardContentSliver(
                    child: HomeDashboardBody(onOpenPrayer: onOpenPrayer),
                  ),
                ],
              );
            },
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
    if ((position.pixels - clampedTarget).abs() <= _heroSnapTolerance) {
      return;
    }

    _animateHomeHeroSnap(context, position, clampedTarget);
  }

  double? _homeHeroSnapTarget(BuildContext context, ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) {
      return null;
    }

    final double collapseExtent = HomeDashboardHeroSliver.collapseScrollExtent(
      context,
    );
    final double offset = metrics.pixels;
    if (offset <= 0 || offset >= collapseExtent) {
      return null;
    }

    final double threshold = collapseExtent * _heroSnapThresholdFactor;
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
