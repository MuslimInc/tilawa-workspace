import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/debug/home_hero_gradient_debug.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa/features/home/domain/home_hero_gradient_resolver.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_hero_collapse.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_collapsed_bar.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_collapsed_toolbar.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_photo_theme.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_context_row.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Variant B — Sliver Hero header: expanded gradient prayer zone + pinned bar.
abstract final class HomeDashboardHeroVariantB {
  const HomeDashboardHeroVariantB._();

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
    final double minExtent = pinnedHeaderExtent(context);
    return homeDashboardHeroCollapseScrollExtent(
      maxExtent: maxExtent,
      minExtent: minExtent,
    );
  }

  /// Pinned toolbar extent (status bar + toolbar).
  static double pinnedHeaderExtent(BuildContext context) {
    return homeDashboardHeroPinnedExtent(
      topInset: MediaQuery.paddingOf(context).top,
    );
  }

  /// Minimum Y for the first content pixel below the pinned bar + safe gap.
  static double contentSafeTopBelowPinnedHeader(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    return pinnedHeaderExtent(context) + tokens.spaceLarge;
  }

  static double contentSheetOverlap(BuildContext context) {
    return TilawaHomeScreenTokens.contentSheetOverlap(context.tokens);
  }

  /// Extra room for sub-pixel layout drift.
  static const double _layoutSlack = 12;

  static double _resolveHeroBodyHeight(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.4);
    final double horizontalGutter =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens) * 2;
    final bool tightCard =
        MediaQuery.sizeOf(context).width - horizontalGutter < 320;
    final double verticalPadding = tokens.spaceSmall + tokens.spaceMedium;
    final double contextRow = 36 * textScale;
    final double prayerBlock = 104 * textScale;
    final double cardPadding = tokens.spaceMedium * 2;
    final double tightSlack = tightCard ? tokens.spaceExtraLarge : 0;
    return verticalPadding +
        tokens.spaceSmall +
        contextRow +
        tokens.spaceSmall +
        prayerBlock +
        cardPadding +
        tightSlack +
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
      HomeHeroGradientDebug.phaseOverride.addListener(_onGradientInputsChanged);
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
      HomeHeroGradientDebug.phaseOverride.removeListener(
        _onGradientInputsChanged,
      );
    }
    _gradientRefreshTimer?.cancel();
    super.dispose();
  }

  void _onGradientInputsChanged() {
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
      _syncGradientRefreshTimer();
    });
  }

  TilawaHomeNextPrayerHeroTokens _resolveHeroTokens() {
    final HomeHeroDayPhase? debugPhaseOverride = kDebugMode
        ? HomeHeroGradientDebug.phaseOverride.value
        : null;
    return HomeHeroPhotoTheme.adapt(
      HomeHeroGradientResolver.resolve(
        now: DateTime.now(),
        boundaries: _dashboard?.prayerBoundaries,
        debugPhaseOverride: debugPhaseOverride,
      ),
    );
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
    final TilawaHomeNextPrayerHeroTokens heroTokens = _resolveHeroTokens();

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

    final TilawaHomeScreenTokens screenTokens = Theme.of(
      context,
    ).componentTokens.homeScreen;
    final Color collapsedBarColor = homeDashboardHeroCollapsedBarColor(
      screenTokens,
    );
    final SystemUiOverlayStyle overlayStyle =
        HomeHeroPhotoTheme.collapsedBarOverlayStyle(collapsedBarColor);

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
        heroTokens.gradientTopStart !=
            oldDelegate.heroTokens.gradientTopStart ||
        heroTokens.gradientBottomEnd !=
            oldDelegate.heroTokens.gradientBottomEnd ||
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

  static const double _expandedFadeStart = 0.18;
  static const double _collapsedFadeEnd = 0.34;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);
    final double t = collapseProgress;
    final double expandedOpacity = _fadeIn(t, start: _expandedFadeStart);
    final double collapsedOpacity = _fadeOut(t, end: _collapsedFadeEnd);
    final double collapsedBarReveal = 1 - Curves.easeInOutCubic.transform(t);
    final double expandedScale = 0.96 + (0.04 * expandedOpacity);
    final double cardRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          ColoredBox(color: screenTokens.backgroundGradientEnd),
          HomeHeroCollapsedBar(reveal: collapsedBarReveal),
          SafeArea(
            bottom: false,
            child: IgnorePointer(
              ignoring: expandedOpacity == 0,
              child: Opacity(
                opacity: expandedOpacity,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: expandedScale,
                      alignment: AlignmentDirectional.bottomCenter,
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: heroBodyHeight,
                        maxHeight: heroBodyHeight,
                        child: SizedBox(
                          height: heroBodyHeight,
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              horizontalInset,
                              tokens.spaceSmall,
                              horizontalInset,
                              tokens.spaceMedium,
                            ),
                            child: DecoratedBox(
                              decoration:
                                  HomeDashboardElevatedSurface.decoration(
                                    context,
                                    borderRadius: BorderRadius.circular(
                                      cardRadius,
                                    ),
                                  ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  cardRadius,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(tokens.spaceMedium),
                                  child: _HomeHeroVariantBExpandedHero(
                                    heroTokens: heroTokens,
                                    locationName: locationName,
                                    isRefreshingLocation: isRefreshingLocation,
                                    onRefreshLocation: onRefreshLocation,
                                    nextPrayer: nextPrayer,
                                    metricsLoading: metricsLoading,
                                    dashboardFailed: dashboardFailed,
                                    onRetryDashboard: onRetryDashboard,
                                    onOpenPrayer: onOpenPrayer,
                                  ),
                                ),
                              ),
                            ),
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
                    start: horizontalInset,
                    end: horizontalInset,
                    bottom: tokens.spaceSmall + tokens.spaceExtraSmall,
                  ),
                  child: Opacity(
                    opacity: collapsedOpacity,
                    child: HomeHeroCollapsedToolbar(
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

class _HomeHeroVariantBExpandedHero extends StatelessWidget {
  const _HomeHeroVariantBExpandedHero({
    required this.heroTokens,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.nextPrayer,
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimDesignTokens tokens = theme.tokens;
    final Color ink = colorScheme.onSurface;
    final Color muted = colorScheme.onSurfaceVariant;

    final Widget metricsChild = dashboardFailed
        ? _HomeHeroVariantBFailure(onCard: ink, onRetry: onRetryDashboard)
        : metricsLoading
        ? _HomeHeroVariantBSkeleton(onCard: ink)
        : _HomeHeroVariantBPrayerFocus(
            nextPrayer: nextPrayer,
            onCard: ink,
            onMuted: muted,
            accent: theme.componentTokens.homeScreen.homePrayerHeroAccent,
            onOpenPrayer: onOpenPrayer,
          );

    return Semantics(
      button: !dashboardFailed,
      label: context.l10n.nextPrayer,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: dashboardFailed ? null : onOpenPrayer,
          splashColor: colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: colorScheme.primary.withValues(alpha: 0.04),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spaceSmall,
                children: [
                  HomePrayerHeroContextRow(
                    locationName: locationName,
                    isRefreshingLocation: isRefreshingLocation,
                    onRefreshLocation: onRefreshLocation,
                    ink: ink,
                    muted: muted,
                  ),
                  metricsChild,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeroVariantBPrayerFocus extends StatelessWidget {
  const _HomeHeroVariantBPrayerFocus({
    required this.nextPrayer,
    required this.onCard,
    required this.onMuted,
    required this.accent,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onCard;
  final Color onMuted;
  final Color accent;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    if (nextPrayer == null) {
      return Text(
        context.l10n.homeNextPrayerUnavailable,
        style: theme.textTheme.titleMedium?.copyWith(
          color: onMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final HomeNextPrayer prayer = nextPrayer!;
    final String prayerName = _localizedPrayerName(context, prayer.type);
    final String timeLabel = _formatTime(context, prayer.time);
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final TextStyle? timeStyle = textScale > 1.2
        ? theme.textTheme.displaySmall
        : theme.textTheme.displayMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceExtraSmall,
      children: [
        Text(
          context.l10n.nextPrayer,
          style: theme.textTheme.labelMedium?.copyWith(
            color: onMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          prayerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onCard,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        Text(
          timeLabel,
          style: timeStyle?.copyWith(
            color: onCard,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 0.98,
          ),
        ),
        _HomeHeroVariantBRemainingText(
          prayerTime: prayer.time,
          color: accent,
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
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.22),
            width: tokens.borderWidthThin,
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spaceSmall,
            vertical: tokens.spaceExtraSmall * 0.75,
          ),
          child: Text(
            _formatCountdown(context, _remaining),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: widget.color,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ),
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
    final MeMuslimDesignTokens tokens = theme.tokens;
    final Color muted = theme.colorScheme.onSurfaceVariant;

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
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
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
    final MeMuslimDesignTokens tokens = theme.tokens;
    final Color muted = theme.colorScheme.onSurfaceVariant;

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
