import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/debug/home_hero_gradient_debug.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/domain/home_hero_gradient_resolver.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_collapse.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hijri_calendar_sheet.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_background.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_collapsed_toolbar.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_photo_theme.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Variant B — compact gold featured-card hero with canvas context row.
///
/// Branded pinned toolbar with hairline separator into the content sheet.
abstract final class HomeDashboardHeroVariantB {
  const HomeDashboardHeroVariantB._();

  /// Gap between hero body content and the pinned header bottom edge.
  static const double sheetOverlap = 8;

  static List<Widget> buildSlivers({
    required BuildContext context,
    required HomeDashboardState state,
    required VoidCallback onOpenPrayer,
  }) {
    return [
      _HomeDashboardHeroVariantBHeader(
        state: state,
        onOpenPrayer: onOpenPrayer,
      ),
    ];
  }

  static double collapseScrollExtent(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double maxExtent = topInset + _resolveHeroBodyHeight(context);
    final double minExtent = homeDashboardHeroPinnedExtent(topInset: topInset);
    return homeDashboardHeroCollapseScrollExtent(
      maxExtent: maxExtent,
      minExtent: minExtent,
    );
  }

  static double contentSheetOverlap(BuildContext context) => sheetOverlap;

  /// Extra room for border width and sub-pixel layout drift.
  static const double _layoutSlack = 12;

  static double _resolveHeroBodyHeight(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3);
    final double contextRow = 40 * textScale;
    final double cardChrome = tokens.spaceSmall * 2 + tokens.spaceSmall;
    final double prayerBlock = 88 * textScale;
    return tokens.spaceSmall +
        contextRow +
        tokens.spaceSmall +
        cardChrome +
        prayerBlock +
        sheetOverlap +
        tokens.spaceExtraSmall +
        _layoutSlack;
  }
}

class _HomeDashboardHeroVariantBHeader extends StatefulWidget {
  const _HomeDashboardHeroVariantBHeader({
    required this.state,
    required this.onOpenPrayer,
  });

  final HomeDashboardState state;
  final VoidCallback onOpenPrayer;

  @override
  State<_HomeDashboardHeroVariantBHeader> createState() =>
      _HomeDashboardHeroVariantBHeaderState();
}

class _HomeDashboardHeroVariantBHeaderState
    extends State<_HomeDashboardHeroVariantBHeader> {
  Timer? _gradientRefreshTimer;

  HomeDashboard? get _dashboard => switch (widget.state) {
    HomeDashboardLoaded(:final dashboard) => dashboard,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      HomeHeroGradientDebug.phaseOverride.addListener(_onDebugInputsChanged);
    }
    _syncGradientRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant _HomeDashboardHeroVariantBHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final HomePrayerDayBoundaries? oldBoundaries = switch (oldWidget.state) {
      HomeDashboardLoaded(:final dashboard) => dashboard.prayerBoundaries,
      _ => null,
    };
    final HomePrayerDayBoundaries? newBoundaries = _dashboard?.prayerBoundaries;
    if (oldWidget.state != widget.state || oldBoundaries != newBoundaries) {
      _syncGradientRefreshTimer();
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      HomeHeroGradientDebug.phaseOverride.removeListener(_onDebugInputsChanged);
    }
    _gradientRefreshTimer?.cancel();
    super.dispose();
  }

  void _onDebugInputsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _syncGradientRefreshTimer();
  }

  void _syncGradientRefreshTimer() {
    _gradientRefreshTimer?.cancel();
    _gradientRefreshTimer = null;

    if (kDebugMode && HomeHeroGradientDebug.phaseOverride.value != null) {
      return;
    }

    final HomePrayerDayBoundaries? boundaries = _dashboard?.prayerBoundaries;
    if (boundaries == null) {
      return;
    }

    _scheduleNextGradientRefresh(boundaries);
  }

  void _scheduleNextGradientRefresh(HomePrayerDayBoundaries boundaries) {
    final Duration? delay =
        HomeHeroGradientResolver.delayUntilNextGradientRefresh(
          now: DateTime.now(),
          boundaries: boundaries,
        );
    if (delay == null) {
      return;
    }

    _gradientRefreshTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _scheduleNextGradientRefresh(boundaries);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final HomeDashboard? dashboard = _dashboard;
    final bool isRefreshingLocation = switch (widget.state) {
      HomeDashboardLoaded(:final isRefreshingLocation) => isRefreshingLocation,
      _ => true,
    };
    final HomeNextPrayer? nextPrayer = switch (widget.state) {
      HomeDashboardLoaded(:final dashboard) => dashboard.nextPrayer,
      _ => null,
    };
    final bool metricsLoading =
        widget.state is! HomeDashboardLoaded &&
        widget.state is! HomeDashboardFailure;
    final bool dashboardFailed = widget.state is HomeDashboardFailure;
    final String? locationName = dashboard?.locationLabel;
    final double heroBodyHeight =
        HomeDashboardHeroVariantB._resolveHeroBodyHeight(
          context,
        );
    final double expandedHeight = topInset + heroBodyHeight;
    final double minExtent = homeDashboardHeroPinnedExtent(topInset: topInset);

    final HomeHeroDayPhase? debugPhaseOverride = kDebugMode
        ? HomeHeroGradientDebug.phaseOverride.value
        : null;

    final TilawaHomeNextPrayerHeroTokens heroTokens = HomeHeroPhotoTheme.adapt(
      HomeHeroGradientResolver.resolve(
        now: DateTime.now(),
        boundaries: dashboard?.prayerBoundaries,
        debugPhaseOverride: debugPhaseOverride,
      ),
    );

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeroVariantBPersistentDelegate(
        topInset: topInset,
        maxExtent: expandedHeight,
        minExtent: minExtent,
        heroTokens: heroTokens,
        nextPrayer: nextPrayer,
        metricsLoading: metricsLoading,
        dashboardFailed: dashboardFailed,
        locationName: locationName,
        isRefreshingLocation: isRefreshingLocation,
        onRefreshLocation: () {
          context.read<HomeDashboardBloc>().add(
            HomeDashboardLocationRefreshRequested(
              localeIdentifier: Localizations.localeOf(context).languageCode,
            ),
          );
        },
        onRetryDashboard: () {
          context.read<HomeDashboardBloc>().add(
            HomeDashboardRefreshRequested(
              localeIdentifier: Localizations.localeOf(context).languageCode,
            ),
          );
        },
        onOpenPrayer: widget.onOpenPrayer,
        heroBodyHeight: heroBodyHeight,
      ),
    );
  }
}

class _HomeHeroVariantBPersistentDelegate
    extends SliverPersistentHeaderDelegate {
  const _HomeHeroVariantBPersistentDelegate({
    required this.topInset,
    required this.maxExtent,
    required this.minExtent,
    required this.heroTokens,
    required this.nextPrayer,
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
    required this.heroBodyHeight,
  });

  final double topInset;
  @override
  final double maxExtent;
  @override
  final double minExtent;
  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;
  final double heroBodyHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double collapseProgress = homeDashboardHeroCollapseProgress(
      shrinkOffset: shrinkOffset,
      maxExtent: maxExtent,
      minExtent: minExtent,
    );

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color collapsedBarColor = homeDashboardHeroCollapsedBarColor(
      heroTokens,
      colorScheme,
    );
    final SystemUiOverlayStyle overlayStyle = collapseProgress < 0.12
        ? HomeHeroPhotoTheme.collapsedBarOverlayStyle(collapsedBarColor)
        : HomeHeroBackground.systemOverlayStyle(heroTokens);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: _HomeHeroVariantBHeaderContent(
        collapseProgress: collapseProgress,
        heroTokens: heroTokens,
        nextPrayer: nextPrayer,
        metricsLoading: metricsLoading,
        dashboardFailed: dashboardFailed,
        locationName: locationName,
        isRefreshingLocation: isRefreshingLocation,
        onRefreshLocation: onRefreshLocation,
        onRetryDashboard: onRetryDashboard,
        onOpenPrayer: onOpenPrayer,
        heroBodyHeight: heroBodyHeight,
      ),
    );
  }

  @override
  bool shouldRebuild(
    covariant _HomeHeroVariantBPersistentDelegate oldDelegate,
  ) {
    return topInset != oldDelegate.topInset ||
        maxExtent != oldDelegate.maxExtent ||
        minExtent != oldDelegate.minExtent ||
        heroTokens != oldDelegate.heroTokens ||
        nextPrayer != oldDelegate.nextPrayer ||
        metricsLoading != oldDelegate.metricsLoading ||
        dashboardFailed != oldDelegate.dashboardFailed ||
        locationName != oldDelegate.locationName ||
        isRefreshingLocation != oldDelegate.isRefreshingLocation ||
        onRefreshLocation != oldDelegate.onRefreshLocation ||
        onRetryDashboard != oldDelegate.onRetryDashboard ||
        onOpenPrayer != oldDelegate.onOpenPrayer ||
        heroBodyHeight != oldDelegate.heroBodyHeight;
  }
}

class _HomeHeroVariantBHeaderContent extends StatelessWidget {
  const _HomeHeroVariantBHeaderContent({
    required this.collapseProgress,
    required this.heroTokens,
    required this.nextPrayer,
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
    required this.heroBodyHeight,
  });

  final double collapseProgress;
  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;
  final double heroBodyHeight;

  static const double _expandedFadeStart = 0.22;
  static const double _collapsedFadeEnd = 0.38;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaBottomSheetScaffoldTokens sheetTokens =
        theme.componentTokens.bottomSheetScaffold;
    final Color collapsedBarColor = homeDashboardHeroCollapsedBarColor(
      heroTokens,
      colorScheme,
    );
    final double t = collapseProgress;
    final double expandedOpacity = _fadeIn(t, start: _expandedFadeStart);
    final double collapsedOpacity = _fadeOut(t, end: _collapsedFadeEnd);
    final double expandedReveal = Curves.easeInOutCubic.transform(t);
    final double collapsedBarReveal = 1 - expandedReveal;

    return Material(
      color: collapsedBarColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant,
              width: sheetTokens.footerTopBorderWidth,
            ),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: expandedReveal,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: colorScheme.surface),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topCenter,
                        end: AlignmentDirectional.bottomCenter,
                        colors: <Color>[
                          heroTokens.gradientTopStart.withValues(alpha: 0.32),
                          heroTokens.gradientBottomEnd.withValues(alpha: 0.06),
                          colorScheme.surface,
                        ],
                        stops: const <double>[0, 0.42, 0.72],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: collapsedBarReveal,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration:
                        HomeHeroPhotoTheme.collapsedBarSurfaceDecoration(
                          collapsedBarColor: collapsedBarColor,
                          heroTokens: heroTokens,
                          colorScheme: colorScheme,
                          tokens: tokens,
                        ),
                  ),
                  DecoratedBox(
                    decoration: HomeHeroPhotoTheme.collapsedBarInnerHighlight(
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              bottom: false,
              child: IgnorePointer(
                ignoring: expandedOpacity == 0,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: heroBodyHeight,
                        maxHeight: heroBodyHeight,
                        child: SizedBox(
                          height: heroBodyHeight,
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              tokens.spaceMedium,
                              tokens.spaceSmall,
                              tokens.spaceMedium,
                              HomeDashboardHeroVariantB.sheetOverlap,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HomeHeroVariantBContextRow(
                                  locationName: locationName,
                                  isRefreshingLocation: isRefreshingLocation,
                                  onRefreshLocation: onRefreshLocation,
                                ),
                                SizedBox(height: tokens.spaceSmall),
                                Expanded(
                                  child: _HomeHeroVariantBPremiumCard(
                                    nextPrayer: nextPrayer,
                                    metricsLoading: metricsLoading,
                                    dashboardFailed: dashboardFailed,
                                    onRetryDashboard: onRetryDashboard,
                                    onOpenPrayer: onOpenPrayer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (collapsedOpacity > 0)
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: tokens.spaceMedium,
                      end: tokens.spaceMedium,
                      bottom: tokens.spaceSmall + tokens.spaceExtraSmall,
                    ),
                    child: Opacity(
                      opacity: collapsedOpacity,
                      child: HomeHeroCollapsedToolbar(
                        heroTokens: heroTokens,
                        collapsedBarColor: collapsedBarColor,
                        nextPrayer: nextPrayer,
                        locationName: locationName,
                        isRefreshingLocation: isRefreshingLocation,
                        onRefreshLocation: onRefreshLocation,
                        onOpenPrayer: onOpenPrayer,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _fadeIn(double t, {required double start}) {
    if (t <= start) {
      return 0;
    }
    return Curves.easeOutCubic.transform(
      ((t - start) / (1 - start)).clamp(0.0, 1.0),
    );
  }

  static double _fadeOut(double t, {required double end}) {
    if (t >= end) {
      return 0;
    }
    return Curves.easeOutCubic.transform(
      ((end - t) / end).clamp(0.0, 1.0),
    );
  }
}

class _HomeHeroVariantBContextRow extends StatelessWidget {
  const _HomeHeroVariantBContextRow({
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color ink = colorScheme.onSurface;
    final Color muted = colorScheme.onSurfaceVariant;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );
    final String hijriDateLine = formatHomeHijriDate(
      date: DateTime.now(),
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceSmall,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: locationLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isRefreshingLocation ? null : onRefreshLocation,
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spaceExtraSmall * 0.5,
                  children: [
                    Text(
                      context.l10n.homeHeroLocationContext,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      spacing: tokens.spaceExtraSmall,
                      children: [
                        Flexible(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isRefreshingLocation)
                          SizedBox(
                            width: tokens.iconSizeSmall,
                            height: tokens.iconSizeSmall,
                            child: TilawaLoadingIndicator(
                              centered: false,
                              strokeWidth: 2,
                              color: ink,
                            ),
                          )
                        else
                          Icon(
                            FluentIcons.chevron_down_24_regular,
                            size: tokens.iconSizeSmall,
                            color: muted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.hijriCalendarOpenLabel,
          child: InkWell(
            onTap: () => showHomeHijriCalendarSheet(context),
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            child: Text(
              hijriDateLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroVariantBPremiumCard extends StatelessWidget {
  const _HomeHeroVariantBPremiumCard({
    required this.nextPrayer,
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;
    final BorderRadius radius = BorderRadius.circular(tokens.radiusExtraLarge);
    final Color onCard = cardTokens.foregroundColor;

    final Widget metricsChild = dashboardFailed
        ? _HomeHeroVariantBFailure(onCard: onCard, onRetry: onRetryDashboard)
        : metricsLoading
        ? _HomeHeroVariantBSkeleton(onCard: onCard)
        : _HomeHeroVariantBPrayerFocus(
            nextPrayer: nextPrayer,
            onCard: onCard,
            onOpenPrayer: onOpenPrayer,
          );

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[cardTokens.gradientStart, cardTokens.gradientEnd],
        ),
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryBrown.withValues(
              alpha: tokens.opacityShadowStrong * 0.28,
            ),
            blurRadius: tokens.blurShadow,
            offset: tokens.shadowOffsetMedium,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            PositionedDirectional(
              end: -tokens.spaceMedium,
              bottom: -tokens.spaceExtraSmall,
              child: IgnorePointer(
                child: Icon(
                  Icons.mosque_outlined,
                  size: tokens.iconSizeExtraLarge * 2.1,
                  color: onCard.withValues(alpha: 0.09),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: metricsChild,
            ),
          ],
        ),
      ),
    );

    if (dashboardFailed) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenPrayer,
        borderRadius: radius,
        splashColor: cardTokens.splashColor,
        highlightColor: cardTokens.highlightColor,
        child: card,
      ),
    );
  }
}

class _HomeHeroVariantBPrayerFocus extends StatelessWidget {
  const _HomeHeroVariantBPrayerFocus({
    required this.nextPrayer,
    required this.onCard,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onCard;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final Color muted = onCard.withValues(alpha: 0.78);

    if (nextPrayer == null) {
      return Text(
        context.l10n.homeNextPrayerUnavailable,
        style: theme.textTheme.titleMedium?.copyWith(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final HomeNextPrayer prayer = nextPrayer!;
    final String prayerName = _localizedPrayerName(context, prayer.type);
    final String timeLabel = _formatTime(context, prayer.time);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceExtraSmall * 0.75,
      children: [
        Text(
          context.l10n.nextPrayer,
          style: theme.textTheme.labelMedium?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          prayerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: onCard,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        Text(
          timeLabel,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: onCard,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
        _HomeHeroVariantBRemainingText(
          prayerTime: prayer.time,
          color: muted,
        ),
      ],
    );
  }
}

class _HomeHeroVariantBRemainingText extends StatefulWidget {
  const _HomeHeroVariantBRemainingText({
    required this.prayerTime,
    required this.color,
  });

  final DateTime prayerTime;
  final Color color;

  @override
  State<_HomeHeroVariantBRemainingText> createState() =>
      _HomeHeroVariantBRemainingTextState();
}

class _HomeHeroVariantBRemainingTextState
    extends State<_HomeHeroVariantBRemainingText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleTicker();
  }

  @override
  void didUpdateWidget(covariant _HomeHeroVariantBRemainingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTime != widget.prayerTime) {
      _scheduleTicker();
    }
  }

  void _scheduleTicker() {
    _ticker?.cancel();
    final Duration remaining = _remaining;
    if (remaining <= Duration.zero) {
      return;
    }

    final Duration interval = remaining < const Duration(hours: 1)
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);

    _ticker = Timer.periodic(interval, (_) {
      if (!mounted) {
        return;
      }
      if (_remaining <= Duration.zero) {
        _ticker?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final Duration difference = widget.prayerTime.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatCountdown(context, _remaining),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: widget.color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _HomeHeroVariantBSkeleton extends StatelessWidget {
  const _HomeHeroVariantBSkeleton({required this.onCard});

  final Color onCard;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceSmall,
      children: [
        TilawaLoadingIndicator(
          centered: false,
          strokeWidth: 2,
          color: onCard,
        ),
        Text(
          context.l10n.homeNextPrayerUnavailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onCard.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroVariantBFailure extends StatelessWidget {
  const _HomeHeroVariantBFailure({
    required this.onCard,
    required this.onRetry,
  });

  final Color onCard;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final Color muted = onCard.withValues(alpha: 0.82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceSmall,
      children: [
        Text(
          context.l10n.homeDashboardLoadError,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: onCard,
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              minimumSize: Size(
                tokens.minInteractiveDimension,
                tokens.minInteractiveDimension,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.retry,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onCard,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _localizedPrayerName(BuildContext context, PrayerType type) {
  return switch (type) {
    PrayerType.fajr => context.l10n.fajr,
    PrayerType.sunrise => context.l10n.sunrise,
    PrayerType.dhuhr => context.l10n.dhuhr,
    PrayerType.asr => context.l10n.asr,
    PrayerType.maghrib => context.l10n.maghrib,
    PrayerType.isha => context.l10n.isha,
    PrayerType.midnight => context.l10n.midnight,
    PrayerType.lastThird => context.l10n.lastThird,
  };
}

String _formatTime(BuildContext context, DateTime time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
  );
}

String _formatCountdown(BuildContext context, Duration duration) {
  if (duration.inMinutes < 1) {
    return context.l10n.homePrayerNow;
  }
  final int totalMinutes = duration.inMinutes;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) {
    return context.l10n.homePrayerInMinutes(minutes);
  }
  return context.l10n.homePrayerInHoursMinutes(hours, minutes);
}
