import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../debug/home_hero_gradient_debug.dart';
import '../../debug/home_hero_variant_debug.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_prayer_day_boundaries.dart';
import '../../domain/home_hijri_date_formatter.dart';
import '../../domain/home_hero_gradient_resolver.dart';
import '../bloc/home_dashboard_bloc.dart';
import 'home_hijri_calendar_sheet.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import 'home_dashboard_hero_collapse.dart';
import 'home_dashboard_hero_variant_b.dart';
import 'home_hero_background.dart';
import 'home_hero_photo_theme.dart';

/// Collapsing gradient hero sliver for the home dashboard.
abstract final class HomeDashboardHeroSliver {
  const HomeDashboardHeroSliver._();

  /// Greeting area: location context row + Hijri date (text-scaled).
  static const double _greetingBodyHeight = 68;

  /// Prayer name/time row + countdown inside the integrated promo card.
  static const double _metricsPrayerBlockHeight = 72;

  /// Extra room for border width and sub-pixel layout drift.
  static const double _metricsLayoutSlack = 12;

  /// Overlap between the hero wave valley and the content sheet.
  static const double sheetOverlap = 8;

  /// Scroll overlap consumed by the hero bottom scallop.
  static double heroWaveOverlap(double waveAmplitude) =>
      waveAmplitude * 0.55 + sheetOverlap;

  /// Header wave amplitude from design tokens.
  static double headerWaveAmplitude(BuildContext context) {
    return Theme.of(
      context,
    ).componentTokens.homeDashboardCard.headerWaveAmplitude;
  }

  /// Active hero layout variant (compact B default; debug may switch to A).
  static HomeHeroDesignVariant activeVariant(BuildContext context) {
    if (!kDebugMode) {
      return HomeHeroDesignVariant.b;
    }
    return HomeHeroVariantDebug.variant.value;
  }

  /// Scroll distance where the hero transitions from expanded to pinned.
  static double collapseScrollExtent(BuildContext context) {
    if (activeVariant(context) == HomeHeroDesignVariant.b) {
      return HomeDashboardHeroVariantB.collapseScrollExtent(context);
    }
    final double topInset = MediaQuery.paddingOf(context).top;
    final double maxExtent = topInset + _resolveHeroBodyHeight(context);
    final double minExtent = homeDashboardHeroPinnedExtent(topInset: topInset);
    return homeDashboardHeroCollapseScrollExtent(
      maxExtent: maxExtent,
      minExtent: minExtent,
    );
  }

  /// Expanded-to-pinned interpolation for hero persistent headers.
  static double collapseProgress({
    required double shrinkOffset,
    required double maxExtent,
    required double minExtent,
  }) {
    return homeDashboardHeroCollapseProgress(
      shrinkOffset: shrinkOffset,
      maxExtent: maxExtent,
      minExtent: minExtent,
    );
  }

  /// Overlap consumed by the content sheet below the hero.
  static double contentSheetOverlap(BuildContext context) {
    if (activeVariant(context) == HomeHeroDesignVariant.b) {
      return HomeDashboardHeroVariantB.contentSheetOverlap(context);
    }
    return heroWaveOverlap(headerWaveAmplitude(context));
  }

  /// Hero is a single pinned [SliverPersistentHeader]; greeting, metrics, and
  /// footer collapse inside a shared persistent header delegate.
  static List<Widget> buildSlivers({
    required BuildContext context,
    required HomeDashboardState state,
    required VoidCallback onOpenPrayer,
  }) {
    if (activeVariant(context) == HomeHeroDesignVariant.b) {
      return HomeDashboardHeroVariantB.buildSlivers(
        context: context,
        state: state,
        onOpenPrayer: onOpenPrayer,
      );
    }
    return [
      _HomeDashboardHeroAppBar(
        state: state,
        onOpenPrayer: onOpenPrayer,
      ),
    ];
  }

  static double _resolveHeroBodyHeight(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3);
    return _greetingBodyHeight * textScale +
        _resolveMetricsMaxHeight(context) +
        _resolveBottomInset(context);
  }

  /// Max height for the frosted next-prayer card in the expanded hero.
  static double _resolveMetricsMaxHeight(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3);
    final double fixedCardChrome = tokens.spaceMedium * 2 + tokens.spaceSmall;
    return fixedCardChrome +
        _metricsPrayerBlockHeight * textScale +
        _metricsLayoutSlack;
  }

  static double _resolveGreetingBodyHeight(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3);
    return _greetingBodyHeight * textScale;
  }

  static double _resolveBottomInset(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final double waveAmplitude = headerWaveAmplitude(context);
    return tokens.spaceSmall + waveAmplitude * 0.35 + sheetOverlap;
  }

  /// Pinned hero chrome when the expanded gradient is fully collapsed.
  ///
  /// Blends phase stops so the bar matches the expanded ramp — never a flat
  /// dark forest block on light pre-dawn/day phases.
  static Color collapsedBarColor(
    TilawaHomeNextPrayerHeroTokens heroTokens,
    ColorScheme colorScheme,
  ) {
    final Color top = heroTokens.gradientTopStart;
    final Color bottom = heroTokens.gradientBottomEnd;
    final bool flatLightCanvas =
        top == bottom && bottom.computeLuminance() > 0.82;
    if (flatLightCanvas) {
      return colorScheme.surfaceContainerHigh;
    }

    if (top.computeLuminance() > 0.72) {
      return Color.lerp(top, bottom, 0.32)!;
    }

    if (bottom.computeLuminance() < 0.35) {
      return Color.lerp(bottom, top, 0.55)!;
    }
    return Color.lerp(top, bottom, 0.58)!;
  }
}

/// Pinned hero [SliverPersistentHeader] with prayer-period gradient refresh.
class _HomeDashboardHeroAppBar extends StatefulWidget {
  const _HomeDashboardHeroAppBar({
    required this.state,
    required this.onOpenPrayer,
  });

  final HomeDashboardState state;
  final VoidCallback onOpenPrayer;

  @override
  State<_HomeDashboardHeroAppBar> createState() =>
      _HomeDashboardHeroAppBarState();
}

class _HomeDashboardHeroAppBarState extends State<_HomeDashboardHeroAppBar> {
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
      HomeHeroVariantDebug.variant.addListener(_onGradientInputsChanged);
    }
    _syncGradientRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant _HomeDashboardHeroAppBar oldWidget) {
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
      HomeHeroVariantDebug.variant.removeListener(_onGradientInputsChanged);
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
        HomeDashboardHeroSliver._resolveHeroBodyHeight(
          context,
        );
    final double bottomInset = HomeDashboardHeroSliver._resolveBottomInset(
      context,
    );
    final double expandedHeight = topInset + heroBodyHeight;

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
    final ThemeData heroTheme = _themeWithHeroTokens(
      Theme.of(context),
      heroTokens,
    );
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color collapsedBarColor = HomeDashboardHeroSliver.collapsedBarColor(
      heroTokens,
      colorScheme,
    );

    return Theme(
      data: heroTheme,
      child: SliverPersistentHeader(
        pinned: true,
        delegate: _HomeHeroVariantAPersistentDelegate(
          topInset: topInset,
          maxExtent: expandedHeight,
          minExtent: homeDashboardHeroPinnedExtent(topInset: topInset),
          collapsedBarColor: collapsedBarColor,
          heroTokens: heroTokens,
          dashboard: dashboard,
          nextPrayer: nextPrayer,
          metricsLoading: metricsLoading,
          dashboardFailed: dashboardFailed,
          locationName: locationName,
          isRefreshingLocation: isRefreshingLocation,
          onRefreshLocation: () {
            context.read<HomeDashboardBloc>().add(
              HomeDashboardLocationRefreshRequested(
                localeIdentifier: Localizations.localeOf(
                  context,
                ).languageCode,
              ),
            );
          },
          onRetryDashboard: () {
            context.read<HomeDashboardBloc>().add(
              HomeDashboardRefreshRequested(
                localeIdentifier: Localizations.localeOf(
                  context,
                ).languageCode,
              ),
            );
          },
          onOpenPrayer: widget.onOpenPrayer,
          bottomInset: bottomInset,
          heroBodyHeight: heroBodyHeight,
        ),
      ),
    );
  }
}

class _HomeHeroVariantAPersistentDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeroVariantAPersistentDelegate({
    required this.topInset,
    required this.maxExtent,
    required this.minExtent,
    required this.collapsedBarColor,
    required this.heroTokens,
    required this.dashboard,
    required this.nextPrayer,
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
    required this.bottomInset,
    required this.heroBodyHeight,
  });

  final double topInset;
  @override
  final double maxExtent;
  @override
  final double minExtent;
  final Color collapsedBarColor;
  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final HomeDashboard? dashboard;
  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;
  final double bottomInset;
  final double heroBodyHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double collapseProgress = HomeDashboardHeroSliver.collapseProgress(
      shrinkOffset: shrinkOffset,
      maxExtent: maxExtent,
      minExtent: minExtent,
    );

    return _HomeHeroFlexibleSpace(
      topInset: topInset,
      collapseProgress: collapseProgress,
      overlapsContent: overlapsContent,
      collapsedBarColor: collapsedBarColor,
      dashboard: dashboard,
      nextPrayer: nextPrayer,
      metricsLoading: metricsLoading,
      dashboardFailed: dashboardFailed,
      locationName: locationName,
      isRefreshingLocation: isRefreshingLocation,
      onRefreshLocation: onRefreshLocation,
      onRetryDashboard: onRetryDashboard,
      onOpenPrayer: onOpenPrayer,
      bottomInset: bottomInset,
      heroBodyHeight: heroBodyHeight,
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeroVariantAPersistentDelegate oldDelegate) {
    return topInset != oldDelegate.topInset ||
        maxExtent != oldDelegate.maxExtent ||
        minExtent != oldDelegate.minExtent ||
        collapsedBarColor != oldDelegate.collapsedBarColor ||
        heroTokens != oldDelegate.heroTokens ||
        dashboard != oldDelegate.dashboard ||
        nextPrayer != oldDelegate.nextPrayer ||
        metricsLoading != oldDelegate.metricsLoading ||
        dashboardFailed != oldDelegate.dashboardFailed ||
        locationName != oldDelegate.locationName ||
        isRefreshingLocation != oldDelegate.isRefreshingLocation ||
        onRefreshLocation != oldDelegate.onRefreshLocation ||
        onRetryDashboard != oldDelegate.onRetryDashboard ||
        onOpenPrayer != oldDelegate.onOpenPrayer ||
        bottomInset != oldDelegate.bottomInset ||
        heroBodyHeight != oldDelegate.heroBodyHeight;
  }
}

ThemeData _themeWithHeroTokens(
  ThemeData theme,
  TilawaHomeNextPrayerHeroTokens heroTokens,
) {
  final TilawaComponentTokens componentTokens = theme.componentTokens.copyWith(
    homeNextPrayerHero: heroTokens,
  );
  final List<ThemeExtension<dynamic>> extensions =
      theme.extensions.values.where((ThemeExtension<dynamic> extension) {
        return extension is! TilawaComponentTokens;
      }).toList()..add(componentTokens);
  return theme.copyWith(extensions: extensions);
}

/// Unified hero persistent header body: one gradient + all hero content.
class _HomeHeroFlexibleSpace extends StatefulWidget {
  const _HomeHeroFlexibleSpace({
    required this.topInset,
    required this.collapseProgress,
    required this.overlapsContent,
    required this.collapsedBarColor,
    required this.dashboard,
    required this.nextPrayer,
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
    required this.bottomInset,
    required this.heroBodyHeight,
  });

  final double topInset;
  final double collapseProgress;
  final bool overlapsContent;
  final Color collapsedBarColor;
  final HomeDashboard? dashboard;
  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;
  final double bottomInset;
  final double heroBodyHeight;

  @override
  State<_HomeHeroFlexibleSpace> createState() => _HomeHeroFlexibleSpaceState();
}

class _HomeHeroFlexibleSpaceState extends State<_HomeHeroFlexibleSpace> {
  static const double _expandedFadeStart = 0.24;
  static const double _collapsedFadeEnd = 0.36;

  late Widget _metricsFooterSection = _buildMetricsFooterSection();

  @override
  void didUpdateWidget(covariant _HomeHeroFlexibleSpace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayer != widget.nextPrayer ||
        oldWidget.metricsLoading != widget.metricsLoading ||
        oldWidget.dashboardFailed != widget.dashboardFailed) {
      _metricsFooterSection = _buildMetricsFooterSection();
    }
  }

  Widget _buildMetricsFooterSection() {
    return _HomeHeroMetricsFooterSection(
      nextPrayer: widget.nextPrayer,
      metricsLoading: widget.metricsLoading,
      dashboardFailed: widget.dashboardFailed,
      onRetryDashboard: widget.onRetryDashboard,
      onOpenPrayer: widget.onOpenPrayer,
    );
  }

  static double _heroFadeIn(double t, {required double start}) {
    if (t <= start) {
      return 0;
    }
    return Curves.easeOutCubic.transform(
      ((t - start) / (1 - start)).clamp(0.0, 1.0),
    );
  }

  static double _heroFadeOut(double t, {required double end}) {
    if (t >= end) {
      return 0;
    }
    return Curves.easeOutCubic.transform(
      ((end - t) / end).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final double t = widget.collapseProgress;
    final double expandedOpacity = _heroFadeIn(
      t,
      start: _expandedFadeStart,
    );
    final double collapsedOpacity = _heroFadeOut(
      t,
      end: _collapsedFadeEnd,
    );
    final double greetingOpacity =
        t > _expandedFadeStart && expandedOpacity > 0 ? expandedOpacity : 0;
    final double expandedReveal = Curves.easeInOutCubic.transform(t);
    final double collapsedBarReveal = 1 - expandedReveal;
    final Color canvasColor = AppColors.homeTravelSheetSurface;
    final SystemUiOverlayStyle overlayStyle =
        HomeHeroBackground.systemOverlayStyle(heroTokens);
    final double waveAmplitude =
        HomeDashboardHeroSliver.headerWaveAmplitude(context);
    final double hairlineAlpha = widget.overlapsContent
        ? 0.45
        : 0.45 * collapsedBarReveal;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Material(
        color: canvasColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
            opacity: collapsedBarReveal,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topCenter,
                  end: AlignmentDirectional.bottomCenter,
                  colors: <Color>[
                    Color.lerp(
                      widget.collapsedBarColor,
                      heroTokens.gradientTopStart,
                      0.28,
                    )!,
                    widget.collapsedBarColor,
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: hairlineAlpha,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: expandedReveal,
            child: HomeHeroBackground(
              heroTokens: heroTokens,
              waveAmplitude: waveAmplitude,
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
                      minHeight: widget.heroBodyHeight,
                      maxHeight: widget.heroBodyHeight,
                      child: SizedBox(
                        height: widget.heroBodyHeight,
                        width: double.infinity,
                        child: _HomeHeroExpandedBody(
                          greetingOpacity: greetingOpacity,
                          locationName: widget.locationName,
                          isRefreshingLocation: widget.isRefreshingLocation,
                          onRefreshLocation: widget.onRefreshLocation,
                          onOpenPrayer: widget.onOpenPrayer,
                          bottomInset: widget.bottomInset,
                          metricsFooterSection: _metricsFooterSection,
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
                    bottom: tokens.spaceSmall,
                  ),
                  child: Opacity(
                    opacity: collapsedOpacity,
                    child: _HomeHeroCollapsedToolbar(
                      nextPrayer: widget.nextPrayer,
                      locationName: widget.locationName,
                      onOpenPrayer: widget.onOpenPrayer,
                      expandedReveal: expandedReveal,
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
}

class _HomeHeroExpandedBody extends StatelessWidget {
  const _HomeHeroExpandedBody({
    required this.greetingOpacity,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onOpenPrayer,
    required this.bottomInset,
    required this.metricsFooterSection,
  });

  final double greetingOpacity;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onOpenPrayer;
  final double bottomInset;
  final Widget metricsFooterSection;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double greetingHeight =
        HomeDashboardHeroSliver._resolveGreetingBodyHeight(context);
    final double metricsMaxHeight =
        HomeDashboardHeroSliver._resolveMetricsMaxHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: greetingOpacity,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.spaceMedium,
              end: tokens.spaceMedium,
            ),
            child: SizedBox(
              height: greetingHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _HomeHeroContextHeader(
                  locationName: locationName,
                  isRefreshingLocation: isRefreshingLocation,
                  onRefreshLocation: onRefreshLocation,
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: metricsMaxHeight),
          child: ClipRect(child: metricsFooterSection),
        ),
        SizedBox(height: bottomInset),
      ],
    );
  }
}

/// Prayer metrics and footer — cached across scroll-driven [LayoutBuilder]
/// rebuilds so countdown/metrics are not reconstructed every frame.
class _HomeHeroMetricsFooterSection extends StatelessWidget {
  const _HomeHeroMetricsFooterSection({
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color cardInk = colorScheme.onSurface;
    final Color cardMuted = colorScheme.onSurfaceVariant;

    final Widget metricsChild = dashboardFailed
        ? _HomeHeroMetricsFailure(
            cardInk: cardInk,
            cardMuted: cardMuted,
            onRetry: onRetryDashboard,
          )
        : metricsLoading
        ? _HomeHeroMetricsSkeleton(
            cardInk: cardInk,
            cardMuted: cardMuted,
          )
        : _HomeHeroNextPrayerFocus(
            nextPrayer: nextPrayer,
            cardInk: cardInk,
            cardMuted: cardMuted,
            onOpenPrayer: onOpenPrayer,
            showEyebrow: true,
            heroTypography: true,
          );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
        child: _HomeHeroIntegratedPrayerCard(
          onTap: dashboardFailed ? null : onOpenPrayer,
          heroTokens: heroTokens,
          child: metricsChild,
        ),
      ),
    );
  }
}

/// Talabat-style integrated promo card inside the branded hero header.
class _HomeHeroIntegratedPrayerCard extends StatelessWidget {
  const _HomeHeroIntegratedPrayerCard({
    required this.child,
    required this.heroTokens,
    this.onTap,
  });

  final Widget child;
  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final BorderRadius radius = BorderRadius.circular(tokens.radiusLarge);
    final Color fill = colorScheme.surface.withValues(alpha: 0.94);
    final Color border = colorScheme.outlineVariant.withValues(alpha: 0.35);

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: border, width: tokens.borderWidthThin),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: tokens.opacityShadowStrong * 0.85,
            ),
            blurRadius: tokens.blurShadow,
            offset: tokens.shadowOffsetMedium,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceMedium,
        ),
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: card,
      ),
    );
  }
}

/// Pinned toolbar row: compact location + prayer summary when collapsed.
class _HomeHeroCollapsedToolbar extends StatelessWidget {
  const _HomeHeroCollapsedToolbar({
    required this.nextPrayer,
    required this.locationName,
    required this.onOpenPrayer,
    required this.expandedReveal,
  });

  final HomeNextPrayer? nextPrayer;
  final String? locationName;
  final VoidCallback onOpenPrayer;
  final double expandedReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color collapsedBarColor = HomeDashboardHeroSliver.collapsedBarColor(
      heroTokens,
      theme.colorScheme,
    );
    final Color foreground = HomeHeroPhotoTheme.collapsedToolbarForeground(
      collapsedBarColor: collapsedBarColor,
      heroTokens: heroTokens,
    );
    final TextStyle? summaryStyle = HomeHeroPhotoTheme.titleStyle(
      theme.textTheme.titleSmall,
      foreground,
      tokens: theme.tokens,
      fontWeight: FontWeight.w700,
    );
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    return switch (nextPrayer) {
      null => Text(
        '$locationLabel · ${context.l10n.homeNextPrayerUnavailable}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: summaryStyle,
      ),
      final prayer => _HomeHeroCollapsedPrayerSummary(
        prayer: prayer,
        locationLabel: locationLabel,
        onOpenPrayer: onOpenPrayer,
        style: summaryStyle!,
      ),
    };
  }
}

class _HomeHeroCollapsedPrayerSummary extends StatefulWidget {
  const _HomeHeroCollapsedPrayerSummary({
    required this.prayer,
    required this.locationLabel,
    required this.onOpenPrayer,
    required this.style,
  });

  final HomeNextPrayer prayer;
  final String locationLabel;
  final VoidCallback onOpenPrayer;
  final TextStyle style;

  @override
  State<_HomeHeroCollapsedPrayerSummary> createState() =>
      _HomeHeroCollapsedPrayerSummaryState();
}

class _HomeHeroCollapsedPrayerSummaryState
    extends State<_HomeHeroCollapsedPrayerSummary> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleTicker();
  }

  @override
  void didUpdateWidget(covariant _HomeHeroCollapsedPrayerSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayer.time != widget.prayer.time) {
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
    final Duration difference = widget.prayer.time.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  Widget build(BuildContext context) {
    final String name = _localizedPrayerName(context, widget.prayer.type);
    final String time = _formatTime(context, widget.prayer.time);
    final String prayerSummary = _remaining <= Duration.zero
        ? '$name · $time · ${context.l10n.homePrayerNow}'
        : '$name · $time · ${_formatCountdown(context, _remaining)}';
    final String summary = '${widget.locationLabel} · $prayerSummary';

    return Semantics(
      button: true,
      label: '$name, $time',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpenPrayer,
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}

class _HomeHeroContextHeader extends StatelessWidget {
  const _HomeHeroContextHeader({
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color chromeInk = HomeHeroPhotoTheme.heroChromeInk(heroTokens);
    final Color chromeMuted = HomeHeroPhotoTheme.heroChromeMuted(
      heroTokens,
      opacity: heroTokens.mutedForegroundOpacity,
    );
    final DateTime now = DateTime.now();
    final String hijriDateLine = formatHomeHijriDate(
      date: now,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceExtraSmall,
      children: [
        Semantics(
          button: true,
          label: locationLabel,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isRefreshingLocation ? null : onRefreshLocation,
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: tokens.spaceSmall,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.spaceExtraSmall * 0.5,
                      children: [
                        Text(
                          context.l10n.homeHeroLocationContext,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeHeroPhotoTheme.labelStyle(
                            theme.textTheme.labelSmall,
                            chromeMuted,
                            tokens: tokens,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HomeHeroPhotoTheme.titleStyle(
                            theme.textTheme.titleSmall,
                            chromeInk,
                            tokens: tokens,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRefreshingLocation)
                    SizedBox(
                      width: tokens.iconSizeSmall,
                      height: tokens.iconSizeSmall,
                      child: TilawaLoadingIndicator(
                        centered: false,
                        strokeWidth: 2,
                        color: chromeInk,
                      ),
                    )
                  else
                    Icon(
                      FluentIcons.chevron_down_24_regular,
                      size: tokens.iconSizeSmall,
                      color: chromeMuted,
                    ),
                ],
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
              style: HomeHeroPhotoTheme.labelStyle(
                theme.textTheme.bodySmall,
                chromeMuted,
                tokens: tokens,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroMetricsFailure extends StatelessWidget {
  const _HomeHeroMetricsFailure({
    required this.cardInk,
    required this.cardMuted,
    required this.onRetry,
  });

  final Color cardInk;
  final Color cardMuted;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceSmall,
      children: [
        Text(
          context.l10n.homeDashboardLoadError,
          style: theme.textTheme.bodyMedium?.copyWith(color: cardMuted),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: cardInk,
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
                color: cardInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroMetricsSkeleton extends StatelessWidget {
  const _HomeHeroMetricsSkeleton({
    required this.cardInk,
    required this.cardMuted,
  });

  final Color cardInk;
  final Color cardMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceLarge,
      children: [
        TilawaLoadingIndicator(
          centered: false,
          strokeWidth: 2,
          color: cardInk,
        ),
        Text(
          context.l10n.homeNextPrayerUnavailable,
          style: theme.textTheme.bodyMedium?.copyWith(color: cardMuted),
        ),
      ],
    );
  }
}

class _HomeHeroNextPrayerFocus extends StatelessWidget {
  const _HomeHeroNextPrayerFocus({
    required this.nextPrayer,
    required this.cardInk,
    required this.cardMuted,
    required this.onOpenPrayer,
    this.showEyebrow = true,
    this.heroTypography = false,
  });

  final HomeNextPrayer? nextPrayer;
  final Color cardInk;
  final Color cardMuted;
  final VoidCallback onOpenPrayer;
  final bool showEyebrow;
  final bool heroTypography;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    if (nextPrayer == null) {
      return Text(
        context.l10n.homeNextPrayerUnavailable,
        style: HomeHeroPhotoTheme.titleStyle(
          theme.textTheme.titleMedium,
          cardMuted,
          tokens: tokens,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final HomeNextPrayer prayer = nextPrayer!;
    final String prayerName = _localizedPrayerName(context, prayer.type);
    final String timeLabel = _formatTime(context, prayer.time);
    final String semanticsLabel =
        '${context.l10n.nextPrayer}: $prayerName, $timeLabel';
    final TextStyle? nameStyle = HomeHeroPhotoTheme.titleStyle(
      heroTypography
          ? theme.textTheme.headlineSmall
          : theme.textTheme.titleMedium,
      cardInk,
      tokens: tokens,
      fontWeight: FontWeight.w700,
    );
    final TextStyle? timeStyle =
        HomeHeroPhotoTheme.titleStyle(
          heroTypography
              ? theme.textTheme.headlineSmall
              : theme.textTheme.titleLarge,
          cardInk,
          tokens: tokens,
        )?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1,
        );

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceExtraSmall,
      children: [
        if (showEyebrow)
          Text(
            context.l10n.nextPrayer,
            style: HomeHeroPhotoTheme.labelStyle(
              theme.textTheme.labelMedium,
              cardMuted,
              tokens: tokens,
              fontWeight: FontWeight.w600,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: tokens.spaceSmall,
          children: [
            Flexible(
              child: Text(
                prayerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nameStyle,
              ),
            ),
            Text(
              timeLabel,
              style: timeStyle,
            ),
          ],
        ),
        _HomeHeroPrayerRemainingText(
          prayerTime: prayer.time,
          color: cardMuted,
        ),
      ],
    );

    if (!showEyebrow) {
      return Semantics(
        label: semanticsLabel,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenPrayer,
          splashColor: cardInk.withValues(alpha: 0.08),
          highlightColor: cardInk.withValues(alpha: 0.04),
          child: content,
        ),
      ),
    );
  }
}

class _HomeHeroPrayerRemainingText extends StatefulWidget {
  const _HomeHeroPrayerRemainingText({
    required this.prayerTime,
    required this.color,
  });

  final DateTime prayerTime;
  final Color color;

  @override
  State<_HomeHeroPrayerRemainingText> createState() =>
      _HomeHeroPrayerRemainingTextState();
}

class _HomeHeroPrayerRemainingTextState
    extends State<_HomeHeroPrayerRemainingText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleTicker();
  }

  @override
  void didUpdateWidget(covariant _HomeHeroPrayerRemainingText oldWidget) {
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
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Text(
      _formatCountdown(context, _remaining),
      style: HomeHeroPhotoTheme.labelStyle(
        theme.textTheme.labelMedium,
        widget.color,
        tokens: tokens,
        fontWeight: FontWeight.w500,
      ),
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
