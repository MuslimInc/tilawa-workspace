import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/debug/home_hero_gradient_debug.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/domain/home_hero_gradient_resolver.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/models/home_dashboard_ui_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_background.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_context_row.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_schedule_strip.dart';
import 'package:tilawa/features/home/presentation/widgets/home_shell_tab_navigation.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Immersive Home header zone — greeting, next prayer, and today's strip.
///
/// MeMuslim header-zone layout on the prayer-period green gradient. Worship IA
/// unchanged (tap opens prayer times).
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
  /// Includes the status-bar inset painted inside the hero (full-bleed band).
  static double expandedLayoutExtent(BuildContext context) {
    return MediaQuery.paddingOf(context).top + _resolveHeroBodyHeight(context);
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

    // Profile + date/location + centered prayer + glass strip.
    // Calibrated at 360dp / textScale 1 against MeMuslim header-zone.
    final double body = 384 * textScale;
    final double tightSlack = tightCard ? tokens.spaceExtraLarge : 0;

    return body + tightSlack;
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
    final ThemeData theme = Theme.of(context);
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final double topInset = MediaQuery.paddingOf(context).top;
    final HomeDashboard? dashboard = widget.ui.dashboard;
    final HomeNextPrayer? nextPrayer = dashboard?.nextPrayer;
    final String? locationName = dashboard?.locationLabel;

    // Figma header-zone uses a fixed bright green ramp — not night/pre-dawn
    // atmospheric phases (those make the strip and inactive copy look muddy).
    final TilawaHomeNextPrayerHeroTokens heroTokens =
        HomeHeroGradientDebug.phaseOverride.value != null
        ? HomeHeroGradientResolver.tokensForPhase(
            HomeHeroGradientDebug.phaseOverride.value!,
          )
        : TilawaHomeNextPrayerHeroTokens.day();
    final Color onHero = heroTokens.foregroundColor;
    final Color muted = onHero.withValues(alpha: 0.7);

    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: HomeHeroBackground.systemOverlayStyle(heroTokens),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: HomeHeroBackground(
                heroTokens: heroTokens,
                screenTokens: screenTokens,
                showDecorativeLayers: false,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                24,
                topInset + 16,
                24,
                24,
              ),
              child: _HomeHeaderZoneBody(
                displayName: dashboard?.displayName,
                photoUrl: dashboard?.photoUrl,
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
                todayPrayers: dashboard?.todayPrayers ?? const [],
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
                onHero: onHero,
                muted: muted,
                heroTokens: heroTokens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderZoneBody extends StatelessWidget {
  const _HomeHeaderZoneBody({
    required this.displayName,
    required this.photoUrl,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.nextPrayer,
    required this.todayPrayers,
    required this.showFullSkeleton,
    required this.showFailure,
    required this.failureIsOffline,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
    required this.onHero,
    required this.muted,
    required this.heroTokens,
  });

  final String? displayName;
  final String? photoUrl;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final HomeNextPrayer? nextPrayer;
  final List<HomePrayerSlot> todayPrayers;
  final bool showFullSkeleton;
  final bool showFailure;
  final bool failureIsOffline;
  final VoidCallback onRetryDashboard;
  final VoidCallback onOpenPrayer;
  final Color onHero;
  final Color muted;
  final TilawaHomeNextPrayerHeroTokens heroTokens;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;

    if (showFullSkeleton) {
      return _HomeHeroSkeletonScope(
        onHero: onHero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: const [
            _HomeHeaderProfileSkeleton(),
            _HomePrayerHeroContextRowSkeleton(),
            _HomeNextPrayerTimeMetricsSkeleton(),
            _HomePrayerScheduleStripSkeleton(),
          ],
        ),
      );
    }

    final Widget prayerBlock = showFailure
        ? _HomeNextPrayerTimeFailure(
            onCard: onHero,
            onRetry: onRetryDashboard,
            message: failureIsOffline
                ? context.l10n.homeDashboardOfflineError
                : context.l10n.homeDashboardLoadError,
          )
        : _HomeNextPrayerTimeFocus(
            nextPrayer: nextPrayer,
            onHero: onHero,
            muted: muted,
            onOpenPrayer: onOpenPrayer,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 0),
          child: _HomeHeaderProfileRow(
            displayName: displayName,
            photoUrl: photoUrl,
            onHero: onHero,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HomePrayerHeroContextRow(
            locationName: locationName,
            isRefreshingLocation: isRefreshingLocation,
            onRefreshLocation: onRefreshLocation,
            ink: onHero,
            muted: muted,
          ),
        ),
        prayerBlock,
        if (!showFailure) ...[
          const SizedBox(height: 14),
          HomePrayerScheduleStrip(
            slots: todayPrayers,
            onHero: onHero,
            heroTokens: heroTokens,
            onOpenPrayer: onOpenPrayer,
          ),
        ],
      ],
    );
  }
}

class _HomeHeaderProfileRow extends StatelessWidget {
  const _HomeHeaderProfileRow({
    required this.displayName,
    required this.photoUrl,
    required this.onHero,
  });

  final String? displayName;
  final String? photoUrl;
  final Color onHero;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final String? name = displayName?.trim();
    final bool hasName = name != null && name.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                context.l10n.homeGreeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: onHero,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  height: 1.15,
                ),
              ),
              if (hasName)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: onHero.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        Semantics(
          button: true,
          label: context.l10n.homeProfileLabel,
          child: TilawaInteractiveSurface(
            onTap: () => openHomeSettingsTab(context),
            borderRadius: BorderRadius.circular(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: onHero.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: ProfileAvatar(
                  photoUrl: photoUrl,
                  displayName: name,
                  size: 45,
                  backgroundColor: onHero.withValues(alpha: 0.14),
                  foregroundColor: onHero,
                  fallbackStyle: ProfileAvatarFallbackStyle.initial,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeNextPrayerTimeFocus extends StatelessWidget {
  const _HomeNextPrayerTimeFocus({
    required this.nextPrayer,
    required this.onHero,
    required this.muted,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final Color onHero;
  final Color muted;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    if (nextPrayer == null) {
      return Text(
        context.l10n.homeNextPrayerUnavailable,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final HomeNextPrayer prayer = nextPrayer!;
    final String prayerName = _localizedPrayerName(context, prayer.type);
    final String timeLabel = _formatHeroClock(prayer.time);
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final TextStyle? timeStyle =
        (textScale > 1.15
                ? theme.textTheme.displayMedium
                : theme.textTheme.displayLarge)
            ?.copyWith(fontSize: textScale > 1.15 ? null : 52);

    return Semantics(
      button: true,
      label: context.l10n.nextPrayer,
      child: TilawaInteractiveSurface(
        onTap: onOpenPrayer,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 2,
          children: [
            Text(
              prayerName.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                fontSize: 15,
                height: 1.2,
              ),
            ),
            Text(
              timeLabel,
              textAlign: TextAlign.center,
              style: timeStyle?.copyWith(
                color: onHero,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            _HomeNextPrayerTimeRemainingText(
              prayerType: prayer.type,
              prayerTime: prayer.time,
              foregroundColor: muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNextPrayerTimeRemainingText extends StatefulWidget {
  const _HomeNextPrayerTimeRemainingText({
    required this.prayerType,
    required this.prayerTime,
    required this.foregroundColor,
  });

  final PrayerType prayerType;
  final DateTime prayerTime;
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

    return Text(
      _formatCountdown(context, _remaining, widget.prayerType),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: widget.foregroundColor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.2,
      ),
    );
  }
}

/// Skeleton scope tinted for immersive green header copy.
class _HomeHeroSkeletonScope extends StatelessWidget {
  const _HomeHeroSkeletonScope({
    required this.child,
    required this.onHero,
  });

  final Widget child;
  final Color onHero;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          surface: onHero.withValues(alpha: 0.18),
        ),
      ),
      child: TilawaSkeleton(
        semanticLabel: context.l10n.loading,
        child: child,
      ),
    );
  }
}

class _HomeHeaderProfileSkeleton extends StatelessWidget {
  const _HomeHeaderProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spaceExtraSmall,
            children: [
              TilawaSkeletonLine(
                width: 180,
                style: theme.textTheme.headlineSmall,
              ),
              TilawaSkeletonLine(
                width: 96,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        TilawaSkeletonBone(
          width: tokens.iconBoxSize,
          height: tokens.iconBoxSize,
          borderRadius: tokens.iconBoxSize / 2,
        ),
      ],
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
        Expanded(
          child: TilawaSkeletonLine(
            width: 160,
            style: theme.textTheme.labelSmall,
          ),
        ),
        TilawaSkeletonBone(
          width: 88,
          height: tokens.minInteractiveDimension * 0.58,
          borderRadius: tokens.radiusLarge,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: tokens.spaceSmall,
      children: [
        TilawaSkeletonLine(
          width: 88,
          style: theme.textTheme.titleMedium,
        ),
        TilawaSkeletonLine(
          width: 160,
          style: theme.textTheme.displayLarge,
        ),
        TilawaSkeletonLine(
          width: 140,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HomePrayerScheduleStripSkeleton extends StatelessWidget {
  const _HomePrayerScheduleStripSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return TilawaSkeletonBone(
      width: double.infinity,
      height: 52,
      borderRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
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
    final Color muted = onCard.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: tokens.spaceSmall,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        TilawaButton(
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

String _formatHeroClock(DateTime time) {
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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
    return context.l10n.homeNextPrayerCountdownMinutes(minutes);
  }
  return context.l10n.homeNextPrayerCountdownHoursMinutes(hours, minutes);
}
