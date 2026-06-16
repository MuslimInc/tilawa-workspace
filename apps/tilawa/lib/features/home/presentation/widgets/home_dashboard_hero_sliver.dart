import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/extensions/prayer_type_ui.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/home_dashboard.dart';
import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import 'home_sliver_app_debug_log.dart';

/// Collapsing gradient hero slivers for the home dashboard (Talabat / MoneyLoop).
abstract final class HomeDashboardHeroSliver {
  const HomeDashboardHeroSliver._();

  /// Greeting area inside the expanded app bar (below toolbar).
  static const double _greetingBodyHeight = 50;

  /// Intrinsic prayer metrics column height (measured at default text scale).
  static const double _metricsContentHeight = 130;

  /// Overlap between the hero and the content sheet lip.
  static const double sheetOverlap = 24;

  /// Location row height in the hero footer (matches chip min height).
  static const double _footerRowHeight = kTilawaMinInteractiveDimension;

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
    required VoidCallback onOpenSettings,
  }) {
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final double topInset = MediaQuery.paddingOf(context).top;

    final HomeDashboard? dashboard = switch (state) {
      HomeDashboardLoaded(:final dashboard) => dashboard,
      _ => null,
    };
    final bool isRefreshingLocation = switch (state) {
      HomeDashboardLoaded(:final isRefreshingLocation) => isRefreshingLocation,
      _ => true,
    };
    final HomeNextPrayer? nextPrayer = switch (state) {
      HomeDashboardLoaded(:final dashboard) => dashboard.nextPrayer,
      _ => null,
    };
    final bool metricsLoading =
        state is! HomeDashboardLoaded && state is! HomeDashboardFailure;
    final String? locationName = dashboard?.locationLabel;
    final double heroBodyHeight = _resolveHeroBodyHeight(context);
    final double bottomInset = _resolveBottomInset(context);
    final double metricsMaxHeight = _resolveMetricsMaxHeight(context);
    final double expandedHeight = topInset + heroBodyHeight;

    final int buildCount = HomeSliverAppDebugLog.bumpBuild('hero_sliver');
    HomeSliverAppDebugLog.log(
      'hero_sliver_build',
      hypothesisId: 'H6',
      data: {
        'buildCount': buildCount,
        'state': state.runtimeType.toString(),
        'expandedHeight': expandedHeight,
        'topInset': topInset,
        'greetingBodyHeight': _greetingBodyHeight,
        'pinStructure': 'single_sliver_app_bar',
      },
    );

    HomeSliverAppDebugLog.log(
      'hero_gradient_layout',
      hypothesisId: 'H8',
      data: {
        'structure': 'single_sliver_app_bar',
        'expandedHeight': expandedHeight,
        'heroBodyHeight': heroBodyHeight,
        'metricsMaxHeight': metricsMaxHeight,
        'bottomInset': bottomInset,
      },
    );

    return [
      SliverAppBar(
        pinned: true,
        stretch: true,
        expandedHeight: expandedHeight,
        backgroundColor: heroTokens.gradientBottomEnd,
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
          onOpenPrayer: onOpenPrayer,
          onOpenSettings: onOpenSettings,
          bottomInset: bottomInset,
          heroBodyHeight: heroBodyHeight,
        ),
      ),
    ];
  }

  static double _resolveHeroBodyHeight(BuildContext context) {
    return _greetingBodyHeight +
        _resolveMetricsMaxHeight(context) +
        _footerRowHeight +
        _resolveBottomInset(context);
  }

  static double _resolveMetricsMaxHeight(BuildContext context) {
    return _metricsContentHeight + Theme.of(context).tokens.spaceSmall;
  }

  static double _resolveBottomInset(BuildContext context) {
    return Theme.of(context).tokens.spaceLarge + sheetOverlap;
  }
}

/// Unified [SliverAppBar] flexible space: one gradient + all hero content.
class _HomeHeroFlexibleSpace extends StatefulWidget {
  const _HomeHeroFlexibleSpace({
    required this.topInset,
    required this.expandedHeight,
    required this.dashboard,
    required this.nextPrayer,
    required this.metricsLoading,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onOpenPrayer,
    required this.onOpenSettings,
    required this.bottomInset,
    required this.heroBodyHeight,
  });

  final double topInset;
  final double expandedHeight;
  final HomeDashboard? dashboard;
  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenSettings;
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
        oldWidget.locationName != widget.locationName ||
        oldWidget.isRefreshingLocation != widget.isRefreshingLocation ||
        oldWidget.bottomInset != widget.bottomInset) {
      _metricsFooterSection = _buildMetricsFooterSection();
      HomeSliverAppDebugLog.log(
        'metrics_footer_cache_refresh',
        hypothesisId: 'H9',
        data: {
          'reason': 'data_changed',
          'metricsLoading': widget.metricsLoading,
          'hasNextPrayer': widget.nextPrayer != null,
        },
      );
    }
  }

  Widget _buildMetricsFooterSection() {
    return _HomeHeroMetricsFooterSection(
      nextPrayer: widget.nextPrayer,
      metricsLoading: widget.metricsLoading,
      locationName: widget.locationName,
      isRefreshingLocation: widget.isRefreshingLocation,
      onRefreshLocation: widget.onRefreshLocation,
      onOpenPrayer: widget.onOpenPrayer,
      bottomInset: widget.bottomInset,
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

        HomeSliverAppDebugLog.logThrottled(
          'flexible_space',
          'flexible_space_layout',
          hypothesisId: 'H1',
          throttleValue: (t * 20).round() / 20,
          data: {
            't': t.toStringAsFixed(3),
            'maxHeight': constraints.maxHeight.toStringAsFixed(1),
            'expandedOpacity': expandedOpacity.toStringAsFixed(3),
            'collapsedOpacity': collapsedOpacity.toStringAsFixed(3),
            'range': range.toStringAsFixed(1),
            'structure': 'single_sliver_app_bar',
          },
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: heroTokens.backgroundGradient,
              ),
            ),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, bodyConstraints) {
                  final double visibleHeight = bodyConstraints.maxHeight.clamp(
                    0.0,
                    widget.heroBodyHeight,
                  );

                  HomeSliverAppDebugLog.logThrottled(
                    'hero_body',
                    'hero_body_clip',
                    hypothesisId: 'H10',
                    throttleValue: (visibleHeight / widget.heroBodyHeight * 20)
                        .round(),
                    data: {
                      'bodyMaxHeight': bodyConstraints.maxHeight
                          .toStringAsFixed(1),
                      'visibleHeight': visibleHeight.toStringAsFixed(1),
                      'heroBodyHeight': widget.heroBodyHeight,
                      'delta': (widget.heroBodyHeight - visibleHeight)
                          .toStringAsFixed(2),
                    },
                  );

                  return IgnorePointer(
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
                                dashboard: widget.dashboard,
                                onOpenSettings: widget.onOpenSettings,
                                metricsFooterSection: _metricsFooterSection,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                        dashboard: widget.dashboard,
                        onOpenSettings: widget.onOpenSettings,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeHeroExpandedBody extends StatelessWidget {
  const _HomeHeroExpandedBody({
    required this.greetingOpacity,
    required this.dashboard,
    required this.onOpenSettings,
    required this.metricsFooterSection,
  });

  final double greetingOpacity;
  final HomeDashboard? dashboard;
  final VoidCallback onOpenSettings;
  final Widget metricsFooterSection;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: HomeDashboardHeroSliver._greetingBodyHeight,
            ),
            metricsFooterSection,
          ],
        ),
        if (greetingOpacity > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spaceMedium,
                end: tokens.spaceMedium,
              ),
              child: Opacity(
                opacity: greetingOpacity,
                child: _HomeHeroHeader(
                  dashboard: dashboard,
                  onOpenSettings: onOpenSettings,
                ),
              ),
            ),
          ),
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
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onOpenPrayer,
    required this.bottomInset,
  });

  final HomeNextPrayer? nextPrayer;
  final bool metricsLoading;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onOpenPrayer;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final tokens = Theme.of(context).tokens;
    final Color onGradient = heroTokens.foregroundColor;

    final Widget metricsChild = metricsLoading
        ? _HomeHeroMetricsSkeleton(onGradient: onGradient)
        : _HomeHeroPrayerMetrics(
            nextPrayer: nextPrayer,
            onGradient: onGradient,
          );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceLarge,
          children: [
            SizedBox(
              height: HomeDashboardHeroSliver._metricsContentHeight,
              child: metricsChild,
            ),
            _HomeHeroPrayerFooter(
              locationName: locationName,
              isRefreshingLocation: isRefreshingLocation,
              onRefreshLocation: onRefreshLocation,
              onOpenPrayer: onOpenPrayer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned toolbar row: title + profile avatar when the hero is collapsed.
class _HomeHeroCollapsedToolbar extends StatelessWidget {
  const _HomeHeroCollapsedToolbar({
    required this.dashboard,
    required this.onOpenSettings,
  });

  final HomeDashboard? dashboard;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;
    final String? displayName = dashboard?.displayName;

    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.homeTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        _HomeHeroProfileMark(
          displayName: displayName,
          photoUrl: dashboard?.photoUrl,
          onTap: onOpenSettings,
        ),
      ],
    );
  }
}

class _HomeHeroHeader extends StatelessWidget {
  const _HomeHeroHeader({
    required this.dashboard,
    required this.onOpenSettings,
  });

  final HomeDashboard? dashboard;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;
    final String? displayName = dashboard?.displayName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.homeTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: onGradient,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                displayName == null
                    ? context.l10n.homeGreeting
                    : context.l10n.homeGreetingName(displayName),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onGradient.withValues(
                    alpha: heroTokens.mutedForegroundOpacity,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        _HomeHeroProfileMark(
          displayName: displayName,
          photoUrl: dashboard?.photoUrl,
          onTap: onOpenSettings,
        ),
      ],
    );
  }
}

class _HomeHeroProfileMark extends StatelessWidget {
  const _HomeHeroProfileMark({
    required this.displayName,
    this.photoUrl,
    this.onTap,
  });

  final String? displayName;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;
    final Color fillColor = onGradient.withValues(
      alpha: heroTokens.locationChipFillOpacity,
    );
    final double avatarSize = tokens.spaceExtraLarge + tokens.spaceExtraSmall;

    return Semantics(
      button: true,
      label: context.l10n.homeProfileLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kTilawaMinInteractiveDimension,
          minHeight: kTilawaMinInteractiveDimension,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: onGradient.withValues(
              alpha: heroTokens.locationChipSplashOpacity,
            ),
            highlightColor: onGradient.withValues(
              alpha: heroTokens.locationChipHighlightOpacity,
            ),
            child: Center(
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: onGradient.withValues(
                      alpha: heroTokens.locationChipBorderOpacity,
                    ),
                    width: tokens.borderWidthThin,
                  ),
                ),
                child: ClipOval(
                  child: ProfileAvatar(
                    photoUrl: photoUrl,
                    displayName: displayName,
                    size: avatarSize,
                    backgroundColor: fillColor,
                    foregroundColor: onGradient,
                    fallbackStyle: ProfileAvatarFallbackStyle.initial,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      color: onGradient,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

class _HomeHeroPrayerMetrics extends StatelessWidget {
  const _HomeHeroPrayerMetrics({
    required this.nextPrayer,
    required this.onGradient,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onGradient;

  @override
  Widget build(BuildContext context) {
    final int buildCount = HomeSliverAppDebugLog.bumpBuild('prayer_metrics');
    HomeSliverAppDebugLog.log(
      'prayer_metrics_build',
      hypothesisId: 'H2',
      data: {
        'buildCount': buildCount,
        'hasNextPrayer': nextPrayer != null,
        'layoutMode': 'flexible_space',
      },
    );

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextPrayer == null)
          Text(
            context.l10n.homeNextPrayerUnavailable,
            style: theme.textTheme.titleLarge?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spaceMedium,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spaceExtraSmall,
                  children: [
                    Text(
                      context.l10n.nextPrayer,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: onGradient.withValues(
                          alpha: heroTokens.mutedForegroundOpacity,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _localizedPrayerName(context, nextPrayer!.type),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: onGradient,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              _HomeHeroPrayerVisual(icon: nextPrayer!.type.icon),
            ],
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            _formatTime(context, nextPrayer!.time),
            style: theme.textTheme.displaySmall?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w800,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          _HomeHeroPrayerRemainingText(prayerTime: nextPrayer!.time),
        ],
      ],
    );
  }
}

class _HomeHeroPrayerFooter extends StatelessWidget {
  const _HomeHeroPrayerFooter({
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onOpenPrayer,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    final BorderRadius prayerActionRadius = BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: kTilawaMinInteractiveDimension,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: tokens.spaceSmall,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: _HomeHeroLocationChip(
            locationLabel: locationLabel,
            isRefreshingLocation: isRefreshingLocation,
            onRefreshLocation: onRefreshLocation,
          ),
        ),
        _HomeHeroPrayerAction(
          label: context.l10n.homePrayerTimesAction,
          borderRadius: prayerActionRadius,
          onTap: onOpenPrayer,
        ),
      ],
    );
  }
}

class _HomeHeroPrayerAction extends StatelessWidget {
  const _HomeHeroPrayerAction({
    required this.label,
    required this.borderRadius,
    required this.onTap,
  });

  final String label;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor.withValues(
      alpha: heroTokens.footerForegroundOpacity,
    );

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: heroTokens.foregroundColor.withValues(
          alpha: heroTokens.locationChipSplashOpacity,
        ),
        highlightColor: heroTokens.foregroundColor.withValues(
          alpha: heroTokens.locationChipHighlightOpacity,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kTilawaMinInteractiveDimension,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spaceExtraSmall,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: onGradient,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: tokens.iconSizeMedium,
                  color: onGradient,
                ),
              ],
            ),
          ),
        ),
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
  const _HomeHeroPrayerRemainingText({required this.prayerTime});

  final DateTime prayerTime;

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
      HomeSliverAppDebugLog.logThrottled(
        'countdown_tick',
        'countdown_tick',
        hypothesisId: 'H4',
        throttleValue: _remaining.inMinutes,
        data: {
          'remainingMinutes': _remaining.inMinutes,
          'intervalSeconds': interval.inSeconds,
        },
      );
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
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;

    return Text(
      _formatCountdown(context, _remaining),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: onGradient.withValues(alpha: heroTokens.mutedForegroundOpacity),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _HomeHeroPrayerVisual extends StatelessWidget {
  const _HomeHeroPrayerVisual({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;

    return Container(
      width: tokens.iconSizeLargePlus,
      height: tokens.iconSizeLargePlus,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onGradient.withValues(
          alpha: heroTokens.locationChipFillOpacity,
        ),
        border: Border.all(
          color: onGradient.withValues(
            alpha: heroTokens.locationChipBorderOpacity,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Icon(
        icon,
        size: tokens.iconSizeLarge,
        color: onGradient,
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
