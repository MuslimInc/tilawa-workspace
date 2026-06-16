import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../debug/home_hero_gradient_debug.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/entities/home_prayer_day_boundaries.dart';
import '../../domain/home_hero_gradient_resolver.dart';
import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';
import 'home_sliver_app_debug_log.dart';

/// Collapsing gradient hero slivers for the home dashboard (Talabat / MoneyLoop).
abstract final class HomeDashboardHeroSliver {
  const HomeDashboardHeroSliver._();

  /// Greeting area inside the expanded app bar (below toolbar).
  static const double _greetingBodyHeight = 56;

  /// Intrinsic prayer focus height (measured at default text scale).
  static const double _metricsContentHeight = 112;

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
    final double topInset = MediaQuery.paddingOf(context).top;
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
      _HomeDashboardHeroAppBar(
        state: state,
        onOpenPrayer: onOpenPrayer,
        onOpenSettings: onOpenSettings,
      ),
    ];
  }

  static double _resolveHeroBodyHeight(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return _greetingBodyHeight +
        tokens.spaceLarge +
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

/// Pinned hero [SliverAppBar] with prayer-period gradient refresh.
class _HomeDashboardHeroAppBar extends StatefulWidget {
  const _HomeDashboardHeroAppBar({
    required this.state,
    required this.onOpenPrayer,
    required this.onOpenSettings,
  });

  final HomeDashboardState state;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenSettings;

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
    if (oldWidget.state != widget.state) {
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

    _gradientRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
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

    final TilawaHomeNextPrayerHeroTokens heroTokens =
        HomeHeroGradientResolver.resolve(
          now: DateTime.now(),
          boundaries: dashboard?.prayerBoundaries,
          debugPhaseOverride: debugPhaseOverride,
        );
    final ThemeData heroTheme = _themeWithHeroTokens(
      Theme.of(context),
      heroTokens,
    );

    return Theme(
      data: heroTheme,
      child: SliverAppBar(
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
          onOpenPrayer: widget.onOpenPrayer,
          onOpenSettings: widget.onOpenSettings,
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
                        nextPrayer: widget.nextPrayer,
                        onOpenPrayer: widget.onOpenPrayer,
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
              height: HomeDashboardHeroSliver._greetingBodyHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _HomeHeroHeader(
                  dashboard: dashboard,
                  onOpenSettings: onOpenSettings,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        metricsFooterSection,
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
        : _HomeHeroNextPrayerFocus(
            nextPrayer: nextPrayer,
            onGradient: onGradient,
            onOpenPrayer: onOpenPrayer,
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
          spacing: tokens.spaceMedium,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: HomeDashboardHeroSliver._metricsContentHeight,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: metricsChild,
              ),
            ),
            _HomeHeroPrayerFooter(
              locationName: locationName,
              isRefreshingLocation: isRefreshingLocation,
              onRefreshLocation: onRefreshLocation,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned toolbar row: compact prayer summary + profile when collapsed.
class _HomeHeroCollapsedToolbar extends StatelessWidget {
  const _HomeHeroCollapsedToolbar({
    required this.dashboard,
    required this.nextPrayer,
    required this.onOpenPrayer,
    required this.onOpenSettings,
  });

  final HomeDashboard? dashboard;
  final HomeNextPrayer? nextPrayer;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;
    final String? displayName = dashboard?.displayName;

    final Widget summary = switch (nextPrayer) {
      null => Text(
        context.l10n.homeNextPrayerUnavailable,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          color: onGradient,
          fontWeight: FontWeight.w700,
        ),
      ),
      final prayer => Semantics(
        button: true,
        label:
            '${_localizedPrayerName(context, prayer.type)}, '
            '${_formatTime(context, prayer.time)}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenPrayer,
            child: Text(
              _collapsedPrayerSummary(context, prayer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: onGradient,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    };

    return Row(
      children: [
        Expanded(child: summary),
        SizedBox(width: tokens.spaceMedium),
        _HomeHeroProfileMark(
          displayName: displayName,
          photoUrl: dashboard?.photoUrl,
          onTap: onOpenSettings,
        ),
      ],
    );
  }

  String _collapsedPrayerSummary(BuildContext context, HomeNextPrayer prayer) {
    final String name = _localizedPrayerName(context, prayer.type);
    final String time = _formatTime(context, prayer.time);
    final Duration remaining = prayer.time.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return '$name · $time · ${context.l10n.homePrayerNow}';
    }
    return '$name · $time · ${_formatCountdown(context, remaining)}';
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
    final Color secondary = onGradient.withValues(
      alpha: heroTokens.footerForegroundOpacity,
    );
    final String? displayName = dashboard?.displayName;

    final Widget greeting = switch (displayName) {
      null => Text(
        context.l10n.homeGreeting,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          color: secondary,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      final name => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.homeGreeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onGradient.withValues(
                alpha: heroTokens.tertiaryForegroundOpacity,
              ),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: secondary,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: greeting),
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

class _HomeHeroNextPrayerFocus extends StatelessWidget {
  const _HomeHeroNextPrayerFocus({
    required this.nextPrayer,
    required this.onGradient,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onGradient;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final int buildCount = HomeSliverAppDebugLog.bumpBuild('prayer_metrics');
    HomeSliverAppDebugLog.log(
      'prayer_metrics_build',
      hypothesisId: 'H2',
      data: {
        'buildCount': buildCount,
        'hasNextPrayer': nextPrayer != null,
        'layoutMode': 'typographic_focus',
      },
    );

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color tertiary = onGradient.withValues(
      alpha: heroTokens.tertiaryForegroundOpacity,
    );
    final Color secondary = onGradient.withValues(
      alpha: heroTokens.footerForegroundOpacity,
    );
    final Color muted = onGradient.withValues(
      alpha: heroTokens.mutedForegroundOpacity,
    );

    if (nextPrayer == null) {
      return Text(
        context.l10n.homeNextPrayerUnavailable,
        style: theme.textTheme.titleMedium?.copyWith(
          color: secondary,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );
    }

    final HomeNextPrayer prayer = nextPrayer!;
    final String prayerName = _localizedPrayerName(context, prayer.type);
    final String timeLabel = _formatTime(context, prayer.time);
    final String semanticsLabel =
        '${context.l10n.nextPrayer}: $prayerName, $timeLabel';

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
          child: Padding(
            padding: EdgeInsets.only(top: tokens.spaceSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.nextPrayer,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Text(
                  prayerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Text(
                  timeLabel,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),
                _HomeHeroPrayerRemainingText(
                  prayerTime: prayer.time,
                  color: muted,
                ),
              ],
            ),
          ),
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
      alignment: AlignmentDirectional.centerStart,
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

    return Text(
      _formatCountdown(context, _remaining),
      style: theme.textTheme.labelMedium?.copyWith(
        color: widget.color,
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
