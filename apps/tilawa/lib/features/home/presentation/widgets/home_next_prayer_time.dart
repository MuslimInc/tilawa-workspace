import 'dart:async';

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
import 'package:tilawa/features/home/presentation/models/home_dashboard_ui_state.dart';
import 'package:tilawa/features/home/presentation/models/home_prayer_hero_foreground_style.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_background.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_glass_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_context_row.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Scrollable next-prayer hero at the top of the Home dashboard.
///
/// TripGlide-inspired craft: atmospheric prayer-period gradient band with a
/// frosted glass metrics card floating over it. Worship IA unchanged.
abstract final class HomeNextPrayerTime {
  const HomeNextPrayerTime._();

  static List<Widget> buildSlivers({
    required BuildContext context,
    required HomeDashboardState state,
    required VoidCallback onOpenPrayer,
  }) {
    final HomeDashboardUiState ui = HomeDashboardUiState.from(state);
    return [
      _HomeNextPrayerTimeSliver(
        ui: ui,
        onOpenPrayer: onOpenPrayer,
      ),
    ];
  }

  /// Hero scrolls away entirely — no expanded-to-pinned transition.
  static double collapseScrollExtent(BuildContext context) => 0;

  static double contentSheetOverlap(BuildContext context) {
    return TilawaHomeScreenTokens.contentSheetOverlap(context.tokens);
  }

  /// Scroll offset that clears the hero from the dashboard viewport.
  ///
  /// The shell reserves the status-bar inset above the scroll view, so this
  /// extent covers only the hero sliver — not [MediaQuery.padding] top.
  static double expandedLayoutExtent(BuildContext context) {
    return _resolveHeroBodyHeight(context);
  }

  static double _resolveHeroBodyHeight(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3);
    final double horizontalGutter =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens) * 2;
    final bool tightCard =
        MediaQuery.sizeOf(context).width - horizontalGutter < 320;

    // Atmospheric band peek + frosted glass card body.
    // Calibrated at 360dp / textScale 1: top Large + card + bottom Medium.
    final double cardBody = 202 * textScale;
    final double tightSlack = tightCard ? tokens.spaceExtraLarge : 0;

    return tokens.spaceLarge + cardBody + tokens.spaceMedium + tightSlack;
  }
}

class _HomeNextPrayerTimeSliver extends StatefulWidget {
  const _HomeNextPrayerTimeSliver({
    required this.ui,
    required this.onOpenPrayer,
  });

  final HomeDashboardUiState ui;
  final VoidCallback onOpenPrayer;

  @override
  State<_HomeNextPrayerTimeSliver> createState() =>
      _HomeNextPrayerTimeSliverState();
}

class _HomeNextPrayerTimeSliverState extends State<_HomeNextPrayerTimeSliver> {
  Timer? _gradientRefreshTimer;

  @override
  void initState() {
    super.initState();
    HomeHeroGradientDebug.phaseOverride.addListener(_onDebugPhaseChanged);
    _scheduleGradientRefresh();
  }

  @override
  void didUpdateWidget(covariant _HomeNextPrayerTimeSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ui.dashboard?.prayerBoundaries !=
        widget.ui.dashboard?.prayerBoundaries) {
      _scheduleGradientRefresh();
    }
  }

  @override
  void dispose() {
    HomeHeroGradientDebug.phaseOverride.removeListener(_onDebugPhaseChanged);
    _gradientRefreshTimer?.cancel();
    super.dispose();
  }

  void _onDebugPhaseChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _scheduleGradientRefresh();
  }

  void _scheduleGradientRefresh() {
    _gradientRefreshTimer?.cancel();
    final HomePrayerDayBoundaries? boundaries =
        widget.ui.dashboard?.prayerBoundaries;
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
      _scheduleGradientRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);
    final HomeDashboard? dashboard = widget.ui.dashboard;
    final HomeNextPrayer? nextPrayer = dashboard?.nextPrayer;
    final String? locationName = dashboard?.locationLabel;
    final Color canvasBottom = screenTokens.backgroundGradientEnd;

    final TilawaHomeNextPrayerHeroTokens heroTokens =
        HomeHeroGradientResolver.resolve(
          now: DateTime.now(),
          boundaries: dashboard?.prayerBoundaries,
          debugPhaseOverride: HomeHeroGradientDebug.phaseOverride.value,
        );

    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: HomeHeroBackground.systemOverlayStyle(heroTokens),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: HomeHeroBackground(
                heroTokens: heroTokens,
                screenTokens: screenTokens,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: tokens.spaceMedium,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        canvasBottom.withValues(alpha: 0),
                        canvasBottom,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                horizontalInset,
                tokens.spaceLarge,
                horizontalInset,
                tokens.spaceMedium,
              ),
              child: _HomeNextPrayerTimeCard(
                locationName: locationName,
                isRefreshingLocation: widget.ui.isRefreshingLocation,
                onRefreshLocation: widget.ui.showContent
                    ? () {
                        context.read<HomeDashboardBloc>().add(
                          HomeDashboardLocationRefreshRequested(
                            localeIdentifier: Localizations.localeOf(
                              context,
                            ).languageCode,
                          ),
                        );
                      }
                    : null,
                nextPrayer: nextPrayer,
                showFullSkeleton: widget.ui.showFullSkeleton,
                showFailure: widget.ui.showFailure,
                failureIsOffline: widget.ui.failureIsOffline,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNextPrayerTimeCard extends StatelessWidget {
  const _HomeNextPrayerTimeCard({
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.nextPrayer,
    required this.showFullSkeleton,
    required this.showFailure,
    required this.failureIsOffline,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final HomeNextPrayer? nextPrayer;
  final bool showFullSkeleton;
  final bool showFailure;
  final bool failureIsOffline;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final HomePrayerHeroForegroundStyle style =
        HomePrayerHeroForegroundStyle.fallback(
          colorScheme: colorScheme,
          screenTokens: screenTokens,
        );

    final Widget metricsChild = showFailure
        ? _HomeNextPrayerTimeFailure(
            onCard: style.ink,
            onRetry: onRetryDashboard,
            message: failureIsOffline
                ? context.l10n.homeDashboardOfflineError
                : context.l10n.homeDashboardLoadError,
          )
        : _HomeNextPrayerTimeFocus(
            nextPrayer: nextPrayer,
            onCard: style.ink,
            onMuted: style.muted,
            onOpenPrayer: onOpenPrayer,
          );

    final Widget cardBody = showFullSkeleton
        ? _HomeHeroSkeletonScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceMedium,
              children: const [
                _HomePrayerHeroContextRowSkeleton(),
                _HomeNextPrayerTimeMetricsSkeleton(),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceSmall + tokens.spaceExtraSmall,
            children: [
              HomePrayerHeroContextRow(
                locationName: locationName,
                isRefreshingLocation: isRefreshingLocation,
                onRefreshLocation: onRefreshLocation,
                ink: style.ink,
                muted: style.muted,
                chipBackground: style.chipBackground,
                chipBorder: style.chipBorder,
              ),
              metricsChild,
            ],
          );

    return Semantics(
      button: !showFailure && !showFullSkeleton,
      label: context.l10n.nextPrayer,
      child: HomeHeroGlassSurface(
        usePrayerHeroTokens: true,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.hero),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceMedium + tokens.spaceExtraSmall,
        ),
        onTap: showFailure || showFullSkeleton ? null : onOpenPrayer,
        child: cardBody,
      ),
    );
  }
}

/// Skeleton scope tinted for the frosted prayer glass surface.
class _HomeHeroSkeletonScope extends StatelessWidget {
  const _HomeHeroSkeletonScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color sheetSurface =
        theme.componentTokens.homeScreen.homePrayerHeroBackground;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(surface: sheetSurface),
      ),
      child: TilawaSkeleton(
        semanticLabel: context.l10n.loading,
        child: child,
      ),
    );
  }
}

class _HomeNextPrayerTimeFocus extends StatelessWidget {
  const _HomeNextPrayerTimeFocus({
    required this.nextPrayer,
    required this.onCard,
    required this.onMuted,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onCard;
  final Color onMuted;
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
    // One step below displayMedium so prayer context stays readable beside the
    // clock — displayMedium only when text scale is reduced.
    final TextStyle? timeStyle = textScale > 1.15
        ? theme.textTheme.headlineMedium
        : theme.textTheme.displaySmall;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceMedium,
      children: [
        HomeDashboardIconWell(
          accent: theme.colorScheme.primary,
          fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
          extent: tokens.iconBoxSize,
          child: Icon(
            Icons.mosque_rounded,
            color: theme.colorScheme.primary,
            size: tokens.iconSizeLarge,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                context.l10n.nextPrayer,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                prayerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
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
              _HomeNextPrayerTimeRemainingText(
                prayerType: prayer.type,
                prayerTime: prayer.time,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeNextPrayerTimeRemainingText extends StatefulWidget {
  const _HomeNextPrayerTimeRemainingText({
    required this.prayerType,
    required this.prayerTime,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final PrayerType prayerType;
  final DateTime prayerTime;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<_HomeNextPrayerTimeRemainingText> createState() =>
      _HomeNextPrayerTimeRemainingTextState();
}

class _HomeNextPrayerTimeRemainingTextState
    extends State<_HomeNextPrayerTimeRemainingText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleTicker();
  }

  @override
  void didUpdateWidget(covariant _HomeNextPrayerTimeRemainingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTime != widget.prayerTime ||
        oldWidget.prayerType != widget.prayerType) {
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
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceExtraSmall,
          ),
          child: Text(
            _formatCountdown(context, _remaining, widget.prayerType),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: widget.foregroundColor,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePrayerHeroContextRowSkeleton extends StatelessWidget {
  const _HomePrayerHeroContextRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: tokens.spaceSmall,
      children: [
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TilawaSkeletonBone(
              width: 112,
              height: tokens.minInteractiveDimension * 0.58,
              borderRadius: tokens.radiusLarge,
            ),
          ),
        ),
        TilawaSkeletonLine(
          width: 88,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _HomeNextPrayerTimeMetricsSkeleton extends StatelessWidget {
  const _HomeNextPrayerTimeMetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final TextStyle? timeStyle = textScale > 1.15
        ? theme.textTheme.headlineMedium
        : theme.textTheme.displaySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceMedium,
      children: [
        TilawaSkeletonLine(
          width: 72,
          style: theme.textTheme.labelSmall,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceSmall,
          children: [
            TilawaSkeletonLine(
              width: 120,
              style: theme.textTheme.titleLarge,
            ),
            TilawaSkeletonLine(width: 160, style: timeStyle),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TilawaSkeletonBone(
            width: 148,
            height: tokens.spaceLarge + tokens.spaceExtraSmall,
            borderRadius: tokens.radiusLarge,
          ),
        ),
      ],
    );
  }
}

class _HomeNextPrayerTimeFailure extends StatelessWidget {
  const _HomeNextPrayerTimeFailure({
    required this.onCard,
    required this.onRetry,
    required this.message,
  });

  final Color onCard;
  final VoidCallback onRetry;
  final String message;

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
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TilawaButton(
            text: context.l10n.retry,
            variant: TilawaButtonVariant.ghost,
            shrinkWrapTapTarget: true,
            foregroundColor: onCard,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              color: onCard,
              fontWeight: FontWeight.w600,
            ),
            onPressed: onRetry,
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

bool _isFiveDailyPrayer(PrayerType type) {
  return switch (type) {
    PrayerType.fajr ||
    PrayerType.dhuhr ||
    PrayerType.asr ||
    PrayerType.maghrib ||
    PrayerType.isha => true,
    _ => false,
  };
}

String _countdownNowLabel(BuildContext context, PrayerType type) {
  if (_isFiveDailyPrayer(type)) {
    return context.l10n.homePrayerNow;
  }

  return switch (type) {
    PrayerType.sunrise => context.l10n.homeSunriseNow,
    // Wire [homeDuhaNow] when [PrayerType.duha] is added to the prayer model.
    _ => context.l10n.prayerNotificationBody(
      _localizedPrayerName(context, type),
    ),
  };
}

String _formatCountdown(
  BuildContext context,
  Duration duration,
  PrayerType type,
) {
  if (duration.inMinutes < 1) {
    return _countdownNowLabel(context, type);
  }
  final int totalMinutes = duration.inMinutes;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) {
    return context.l10n.homePrayerInMinutes(minutes);
  }
  return context.l10n.homePrayerInHoursMinutes(hours, minutes);
}
