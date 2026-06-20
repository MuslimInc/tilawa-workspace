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
import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_prayer_day_boundaries.dart';
import '../../domain/home_hijri_date_formatter.dart';
import '../../domain/home_hero_gradient_resolver.dart';
import '../bloc/home_dashboard_bloc.dart';
import 'home_hijri_calendar_sheet.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import 'home_hero_background.dart';
import 'home_hero_glass_surface.dart';
import 'home_hero_photo_theme.dart';

/// Collapsing gradient hero sliver for the home dashboard.
abstract final class HomeDashboardHeroSliver {
  const HomeDashboardHeroSliver._();

  /// Greeting area inside the expanded app bar (below toolbar).
  static const double _greetingBodyHeight = 56;

  /// Frosted next-prayer card (compact glass padding + rows + countdown).
  static const double _metricsContentHeight = 140;

  /// Extra room for device font metrics / text-scale drift.
  static const double _metricsLayoutSlack = 4;

  /// Overlap between the hero and the content sheet lip.
  static const double sheetOverlap = 16;

  /// Scroll distance where the hero transitions from expanded to pinned.
  static double collapseScrollExtent(BuildContext context) {
    return _resolveHeroBodyHeight(context) - kToolbarHeight;
  }

  /// Hero is a single pinned [SliverAppBar]; greeting, metrics, and footer
  /// live in [flexibleSpace] on one shared gradient background.
  static List<Widget> buildSlivers({
    required BuildContext context,
    required HomeDashboardState state,
    required VoidCallback onOpenPrayer,
  }) {
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
        _metricsContentHeight * textScale +
        _metricsLayoutSlack +
        _resolveBottomInset(context);
  }

  static double _resolveGreetingBodyHeight(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3);
    return _greetingBodyHeight * textScale;
  }

  static double _resolveBottomInset(BuildContext context) {
    return Theme.of(context).tokens.spaceSmall + sheetOverlap;
  }

  /// Pinned hero chrome when the wallpaper is fully hidden.
  ///
  /// Uses the prayer-period tint when it differs from the flat canvas; otherwise
  /// a slightly elevated neutral so the bar reads above white content cards.
  static Color collapsedBarColor(TilawaHomeNextPrayerHeroTokens heroTokens) {
    final Color phaseTint = heroTokens.gradientBottomEnd;
    if (phaseTint != AppColors.tripGlideCanvas) {
      return phaseTint;
    }
    return AppColors.tripGlideCanvasElevated;
  }
}

/// Pinned hero [SliverAppBar] with prayer-period gradient refresh.
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
    final Color collapsedBarColor = HomeDashboardHeroSliver.collapsedBarColor(
      heroTokens,
    );

    return Theme(
      data: heroTheme,
      child: SliverAppBar(
        pinned: true,
        stretch: true,
        expandedHeight: expandedHeight,
        backgroundColor: collapsedBarColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: heroTokens.foregroundColor,
        automaticallyImplyLeading: false,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: _HomeHeroFlexibleSpace(
          topInset: topInset,
          expandedHeight: expandedHeight,
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

/// Unified [SliverAppBar] flexible space: one gradient + all hero content.
class _HomeHeroFlexibleSpace extends StatefulWidget {
  const _HomeHeroFlexibleSpace({
    required this.topInset,
    required this.expandedHeight,
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
  final double expandedHeight;
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
        oldWidget.dashboardFailed != widget.dashboardFailed ||
        oldWidget.locationName != widget.locationName ||
        oldWidget.isRefreshingLocation != widget.isRefreshingLocation) {
      _metricsFooterSection = _buildMetricsFooterSection();
    }
  }

  Widget _buildMetricsFooterSection() {
    return _HomeHeroMetricsFooterSection(
      nextPrayer: widget.nextPrayer,
      metricsLoading: widget.metricsLoading,
      dashboardFailed: widget.dashboardFailed,
      locationName: widget.locationName,
      isRefreshingLocation: widget.isRefreshingLocation,
      onRefreshLocation: widget.onRefreshLocation,
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
    final double collapsedHeight = widget.topInset + kToolbarHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double range = widget.expandedHeight - collapsedHeight;
        final double t = range <= 0
            ? 0
            : ((constraints.maxHeight - collapsedHeight) / range).clamp(
                0.0,
                1.0,
              );
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
        final double wallpaperReveal = Curves.easeInOutCubic.transform(t);
        final double collapsedBarReveal = 1 - wallpaperReveal;
        final Color canvasColor = context.scaffoldCanvasColor;
        final Color collapsedBarColor =
            HomeDashboardHeroSliver.collapsedBarColor(heroTokens);
        final SystemUiOverlayStyle overlayStyle = wallpaperReveal > 0.5
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: canvasColor),
              Opacity(
                opacity: collapsedBarReveal,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.topCenter,
                      end: AlignmentDirectional.bottomCenter,
                      colors: <Color>[
                        Color.lerp(
                          collapsedBarColor,
                          heroTokens.gradientTopStart,
                          0.28,
                        )!,
                        collapsedBarColor,
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.45 * collapsedBarReveal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: wallpaperReveal,
                child: HomeHeroBackground(heroTokens: heroTokens),
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
                          onOpenPrayer: widget.onOpenPrayer,
                          wallpaperReveal: wallpaperReveal,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeroExpandedBody extends StatelessWidget {
  const _HomeHeroExpandedBody({
    required this.greetingOpacity,
    required this.onOpenPrayer,
    required this.bottomInset,
    required this.metricsFooterSection,
  });

  final double greetingOpacity;
  final VoidCallback onOpenPrayer;
  final double bottomInset;
  final Widget metricsFooterSection;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

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
              height: HomeDashboardHeroSliver._resolveGreetingBodyHeight(
                context,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _HomeHeroHeader(),
              ),
            ),
          ),
        ),
        metricsFooterSection,
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
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final bool dashboardFailed;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final tokens = Theme.of(context).tokens;
    final Color onGradient = heroTokens.foregroundColor;

    final Widget metricsChild = dashboardFailed
        ? _HomeHeroMetricsFailure(
            onGradient: onGradient,
            onRetry: onRetryDashboard,
          )
        : metricsLoading
        ? _HomeHeroMetricsSkeleton(onGradient: onGradient)
        : _HomeHeroNextPrayerFocus(
            nextPrayer: nextPrayer,
            onGradient: onGradient,
            onOpenPrayer: onOpenPrayer,
            showEyebrow: false,
          );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
        child: HomeHeroGlassSurface(
          onTap: dashboardFailed ? null : onOpenPrayer,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceSmall,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceSmall,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.nextPrayer,
                      style: HomeHeroPhotoTheme.labelStyle(
                        Theme.of(context).textTheme.labelMedium,
                        onGradient.withValues(
                          alpha: heroTokens.tertiaryForegroundOpacity,
                        ),
                        tokens: tokens,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _HomeHeroPrayerFooter(
                    locationName: locationName,
                    isRefreshingLocation: isRefreshingLocation,
                    onRefreshLocation: onRefreshLocation,
                  ),
                ],
              ),
              metricsChild,
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned toolbar row: compact prayer summary when collapsed.
class _HomeHeroCollapsedToolbar extends StatelessWidget {
  const _HomeHeroCollapsedToolbar({
    required this.nextPrayer,
    required this.onOpenPrayer,
    required this.wallpaperReveal,
  });

  final HomeNextPrayer? nextPrayer;
  final VoidCallback onOpenPrayer;
  final double wallpaperReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color foreground = Color.lerp(
      AppColors.tripGlideInk,
      heroTokens.foregroundColor,
      wallpaperReveal,
    )!;
    final TextStyle? summaryStyle = wallpaperReveal > 0.5
        ? HomeHeroPhotoTheme.titleStyle(
            theme.textTheme.titleSmall,
            foreground,
            tokens: theme.tokens,
          )
        : theme.textTheme.titleSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            height: 1.1,
          );

    return switch (nextPrayer) {
      null => Text(
        context.l10n.homeNextPrayerUnavailable,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: summaryStyle,
      ),
      final prayer => _HomeHeroCollapsedPrayerSummary(
        prayer: prayer,
        onOpenPrayer: onOpenPrayer,
        style: summaryStyle!,
      ),
    };
  }
}

class _HomeHeroCollapsedPrayerSummary extends StatefulWidget {
  const _HomeHeroCollapsedPrayerSummary({
    required this.prayer,
    required this.onOpenPrayer,
    required this.style,
  });

  final HomeNextPrayer prayer;
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
    final String summary = _remaining <= Duration.zero
        ? '$name · $time · ${context.l10n.homePrayerNow}'
        : '$name · $time · ${_formatCountdown(context, _remaining)}';

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

class _HomeHeroHeader extends StatelessWidget {
  const _HomeHeroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;
    final DateTime now = DateTime.now();
    final String hijriDateLine = formatHomeHijriDate(
      date: now,
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Semantics(
      button: true,
      label: context.l10n.hijriCalendarOpenLabel,
      child: InkWell(
        onTap: () => showHomeHijriCalendarSheet(context),
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hijriDateLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomeHeroPhotoTheme.labelStyle(
                theme.textTheme.bodyMedium,
                onGradient.withValues(
                  alpha: heroTokens.footerForegroundOpacity,
                ),
                tokens: tokens,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroMetricsFailure extends StatelessWidget {
  const _HomeHeroMetricsFailure({
    required this.onGradient,
    required this.onRetry,
  });

  final Color onGradient;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceSmall,
      children: [
        Text(
          context.l10n.homeDashboardLoadError,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onGradient.withValues(
              alpha: heroTokens.footerForegroundOpacity,
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: onGradient,
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
                color: onGradient,
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
  const _HomeHeroMetricsSkeleton({required this.onGradient});

  final Color onGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceLarge,
      children: [
        TilawaLoadingIndicator(
          centered: false,
          strokeWidth: 2,
          color: onGradient,
        ),
        Text(
          context.l10n.homeNextPrayerUnavailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onGradient.withValues(
              alpha: heroTokens.mutedForegroundOpacity,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroNextPrayerFocus extends StatelessWidget {
  const _HomeHeroNextPrayerFocus({
    required this.nextPrayer,
    required this.onGradient,
    required this.onOpenPrayer,
    this.showEyebrow = true,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onGradient;
  final VoidCallback onOpenPrayer;
  final bool showEyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;

    if (nextPrayer == null) {
      return Text(
        context.l10n.homeNextPrayerUnavailable,
        style: HomeHeroPhotoTheme.titleStyle(
          theme.textTheme.titleMedium,
          onGradient.withValues(alpha: heroTokens.footerForegroundOpacity),
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

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceExtraSmall,
      children: [
        if (showEyebrow)
          Text(
            context.l10n.nextPrayer,
            style: HomeHeroPhotoTheme.labelStyle(
              theme.textTheme.labelSmall,
              onGradient.withValues(
                alpha: heroTokens.tertiaryForegroundOpacity,
              ),
              tokens: tokens,
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
                style: HomeHeroPhotoTheme.titleStyle(
                  theme.textTheme.titleMedium,
                  onGradient.withValues(
                    alpha: heroTokens.footerForegroundOpacity,
                  ),
                  tokens: tokens,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              timeLabel,
              style:
                  HomeHeroPhotoTheme.titleStyle(
                    theme.textTheme.titleLarge,
                    onGradient,
                    tokens: tokens,
                  )?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1,
                  ),
            ),
          ],
        ),
        _HomeHeroPrayerRemainingText(
          prayerTime: prayer.time,
          color: onGradient.withValues(
            alpha: heroTokens.mutedForegroundOpacity,
          ),
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
          splashColor: onGradient.withValues(
            alpha: heroTokens.locationChipSplashOpacity,
          ),
          highlightColor: onGradient.withValues(
            alpha: heroTokens.locationChipHighlightOpacity,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _HomeHeroPrayerFooter extends StatelessWidget {
  const _HomeHeroPrayerFooter({
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: _HomeHeroLocationChip(
        locationLabel: locationLabel,
        isRefreshingLocation: isRefreshingLocation,
        onRefreshLocation: onRefreshLocation,
      ),
    );
  }
}

class _HomeHeroLocationChip extends StatelessWidget {
  const _HomeHeroLocationChip({
    required this.locationLabel,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String locationLabel;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final chipTokens = theme.componentTokens.chip;
    final Color onGradient = heroTokens.foregroundColor;

    final TextStyle textStyle =
        theme.textTheme.labelMedium?.copyWith(
          color: onGradient,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(color: onGradient, fontWeight: FontWeight.w600);

    final double iconSize = chipTokens.inlineIconSize;
    final BorderRadius chipRadius = BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: kTilawaMinInteractiveDimension,
      ),
    );

    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: chipRadius,
      side: BorderSide(
        color: onGradient.withValues(
          alpha: heroTokens.locationChipBorderOpacity,
        ),
        width: tokens.borderWidthThin,
      ),
    );

    Widget paintedChip({required double? maxLabelWidth}) {
      final Widget label = Text(
        locationLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );

      return Material(
        color: onGradient.withValues(
          alpha: heroTokens.locationChipFillOpacity,
        ),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isRefreshingLocation ? null : onRefreshLocation,
          customBorder: shape,
          splashColor: onGradient.withValues(
            alpha: heroTokens.locationChipSplashOpacity,
          ),
          highlightColor: onGradient.withValues(
            alpha: heroTokens.locationChipHighlightOpacity,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kTilawaMinInteractiveDimension,
              minHeight: kTilawaMinInteractiveDimension,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceExtraSmall,
                children: [
                  if (isRefreshingLocation)
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: TilawaLoadingIndicator(
                        centered: false,
                        strokeWidth: 2,
                        color: onGradient,
                      ),
                    )
                  else
                    Icon(
                      FluentIcons.location_24_regular,
                      size: iconSize,
                      color: onGradient,
                    ),
                  if (maxLabelWidth != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxLabelWidth),
                      child: label,
                    )
                  else
                    label,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: locationLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double horizontalPadding = tokens.spaceSmall * 2;
          final double leadingWidth = iconSize + tokens.spaceExtraSmall;
          final double? maxLabelWidth = constraints.hasBoundedWidth
              ? (constraints.maxWidth - horizontalPadding - leadingWidth).clamp(
                  0,
                  double.infinity,
                )
              : null;

          return Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: paintedChip(maxLabelWidth: maxLabelWidth),
          );
        },
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
