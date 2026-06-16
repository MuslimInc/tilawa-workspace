import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import '../widgets/home_dashboard_content_sliver.dart';
import '../widgets/home_dashboard_hero_sliver.dart';
import '../widgets/home_sliver_app_debug_log.dart';

/// Main daily dashboard for the app shell.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenReciters,
    required this.onOpenPrayer,
    required this.onOpenAthkar,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenReciters;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenAthkar;
  final VoidCallback onOpenSettings;

  static const double _heroSnapThresholdFactor = 0.35;
  static const double _heroSnapTolerance = 0.5;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final Color sheetColor = context.scaffoldCanvasColor;
    final double topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: sheetColor,
      body: RefreshIndicator(
        edgeOffset: topInset + kToolbarHeight,
        onRefresh: () async {
          context.read<HomeDashboardBloc>().add(
            HomeDashboardRefreshRequested(
              localeIdentifier: Localizations.localeOf(context).languageCode,
            ),
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
                    onOpenSettings: onOpenSettings,
                  ),
                  HomeDashboardContentSliver(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isSmartKhatmaEnabled()) ...[
                          const SmartKhatmaHomeEntryCard(),
                          SizedBox(height: tokens.spaceMedium),
                        ],
                        if (isTodayPlanEnabled()) ...[
                          const TodayPlanCard(),
                          SizedBox(height: tokens.spaceLarge),
                        ],
                        TilawaSectionTitle(
                          title: context.l10n.homeExploreTitle,
                        ),
                        SizedBox(height: tokens.spaceSmall),
                        _QuickActionsGrid(
                          actions: [
                            _HomeQuickAction(
                              label: context.l10n.homeQuickQuran,
                              icon: Icons.menu_book_rounded,
                              onTap: () => _openReaderAndRefreshPlans(context),
                            ),
                            _HomeQuickAction(
                              label: context.l10n.homeQuickReciters,
                              icon: FluentIcons.person_voice_24_regular,
                              onTap: onOpenReciters,
                            ),
                            _HomeQuickAction(
                              label: context.l10n.homeQuickPrayer,
                              icon: FluentIcons.clock_24_regular,
                              onTap: onOpenPrayer,
                            ),
                            _HomeQuickAction(
                              label: context.l10n.homeQuickQibla,
                              icon: FluentIcons.compass_northwest_24_regular,
                              onTap: () => const QiblaRoute().push(context),
                            ),
                            _HomeQuickAction(
                              label: context.l10n.homeQuickAthkar,
                              icon: FluentIcons.book_open_24_regular,
                              onTap: onOpenAthkar,
                            ),
                            _HomeQuickAction(
                              label: context.l10n.homeQuickSettings,
                              icon: FluentIcons.settings_24_regular,
                              onTap: onOpenSettings,
                            ),
                          ],
                        ),
                        SizedBox(height: tokens.spaceLarge),
                        _DailyContentCard(
                          label: context.l10n.homeDailyAyahLabel,
                          body: context.l10n.homeDailyAyahBody,
                          footer: context.l10n.homeDailyAyahReference,
                        ),
                        SizedBox(height: tokens.spaceSmall),
                        _DailyContentCard(
                          label: context.l10n.homeDailyDuaLabel,
                          body: context.l10n.homeDailyDuaBody,
                          footer: context.l10n.homeDailyDuaReference,
                        ),
                      ],
                    ),
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

    if (notification is ScrollUpdateNotification) {
      HomeSliverAppDebugLog.logThrottled(
        'scroll',
        'scroll_update',
        hypothesisId: 'H5',
        throttleValue: (notification.metrics.pixels / 16).round(),
        data: {
          'pixels': notification.metrics.pixels.toStringAsFixed(1),
          'maxScrollExtent': notification.metrics.maxScrollExtent
              .toStringAsFixed(1),
          'axis': notification.metrics.axisDirection.name,
        },
      );
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

  Future<void> _openReaderAndRefreshPlans(BuildContext context) async {
    await const QuranLastReadRoute().push(context);
    if (!context.mounted) {
      return;
    }
    if (isSmartKhatmaEnabled()) {
      context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
    }
    if (isTodayPlanEnabled()) {
      context.read<TodayPlanBloc>().add(const TodayPlanSourceChanged());
    }
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 520 ? 3 : 2;
        final double gap = tokens.spaceSmall;
        final double tileWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth,
                child: _QuickActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final colorScheme = theme.colorScheme;
    final tileFill = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;

    return TilawaCard(
      surface: TilawaCardSurface.raised,
      backgroundColor: tileFill,
      padding: EdgeInsets.zero,
      onTap: action.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                action.icon,
                color: colorScheme.primary,
                size: tokens.iconSizeLarge,
              ),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _DailyContentCard extends StatelessWidget {
  const _DailyContentCard({
    required this.label,
    required this.body,
    required this.footer,
  });

  final String label;
  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return _HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            body,
            textAlign: TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.55,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              footer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: child,
    );
  }
}
