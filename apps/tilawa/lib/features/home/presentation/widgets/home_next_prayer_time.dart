import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_event.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_hero_context_row.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Scrollable next-prayer card at the top of the Home dashboard.
abstract final class HomeNextPrayerTime {
  const HomeNextPrayerTime._();

  static List<Widget> buildSlivers({
    required BuildContext context,
    required HomeDashboardState state,
    required VoidCallback onOpenPrayer,
  }) {
    return [
      _HomeNextPrayerTimeSliver(
        state: state,
        onOpenPrayer: onOpenPrayer,
      ),
    ];
  }

  /// Hero scrolls away entirely — no expanded-to-pinned transition.
  static double collapseScrollExtent(BuildContext context) => 0;

  static double contentSheetOverlap(BuildContext context) {
    return TilawaHomeScreenTokens.contentSheetOverlap(context.tokens);
  }

  /// Full hero layout extent (status bar + card body).
  static double expandedLayoutExtent(BuildContext context) {
    return MediaQuery.paddingOf(context).top + _resolveHeroBodyHeight(context);
  }

  /// Scroll offset where the featured tutor card sticks under the status bar.
  static double scrollOffsetWhenTutorCardPins(BuildContext context) {
    return expandedLayoutExtent(context);
  }

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

class _HomeNextPrayerTimeSliver extends StatelessWidget {
  const _HomeNextPrayerTimeSliver({
    required this.state,
    required this.onOpenPrayer,
  });

  final HomeDashboardState state;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final double topInset = MediaQuery.paddingOf(context).top;
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);
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
    final bool dashboardFailed = state is HomeDashboardFailure;
    final String? locationName = dashboard?.locationLabel;
    final double cardRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );
    final BorderRadius borderRadius = BorderRadius.circular(cardRadius);

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          horizontalInset,
          topInset + tokens.spaceSmall,
          horizontalInset,
          tokens.spaceMedium,
        ),
        child: DecoratedBox(
          decoration: HomeDashboardElevatedSurface.decoration(
            context,
            borderRadius: borderRadius,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: _HomeNextPrayerTimeCard(
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
                nextPrayer: nextPrayer,
                metricsLoading: metricsLoading,
                dashboardFailed: dashboardFailed,
                onRetryDashboard: () {
                  context.read<HomeDashboardBloc>().add(
                    HomeDashboardRefreshRequested(
                      localeIdentifier: Localizations.localeOf(
                        context,
                      ).languageCode,
                    ),
                  );
                },
                onOpenPrayer: onOpenPrayer,
              ),
            ),
          ),
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
    required this.metricsLoading,
    required this.dashboardFailed,
    required this.onRetryDashboard,
    required this.onOpenPrayer,
  });

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
        ? _HomeNextPrayerTimeFailure(onCard: ink, onRetry: onRetryDashboard)
        : metricsLoading
        ? _HomeNextPrayerTimeSkeleton(onCard: ink)
        : _HomeNextPrayerTimeFocus(
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
          child: Column(
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
        ),
      ),
    );
  }
}

class _HomeNextPrayerTimeFocus extends StatelessWidget {
  const _HomeNextPrayerTimeFocus({
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
        _HomeNextPrayerTimeRemainingText(
          prayerTime: prayer.time,
          color: accent,
        ),
      ],
    );
  }
}

class _HomeNextPrayerTimeRemainingText extends StatefulWidget {
  const _HomeNextPrayerTimeRemainingText({
    required this.prayerTime,
    required this.color,
  });

  final DateTime prayerTime;
  final Color color;

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

class _HomeNextPrayerTimeSkeleton extends StatelessWidget {
  const _HomeNextPrayerTimeSkeleton({required this.onCard});

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

class _HomeNextPrayerTimeFailure extends StatelessWidget {
  const _HomeNextPrayerTimeFailure({
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
