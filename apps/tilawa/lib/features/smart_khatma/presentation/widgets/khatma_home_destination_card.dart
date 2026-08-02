import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Smart Khatma home entry — solid primary fill + on-primary chrome.
///
/// Explicit brand green body (same family as hero / CTAs). White peers stay
/// white; this is the one solid-primary habit card on Home.
class KhatmaHomeDestinationCard extends StatelessWidget {
  const KhatmaHomeDestinationCard({
    super.key,
    required this.icon,
    required this.onTap,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.statusChipLabel,
    this.detail,
    this.actionLabel,
    this.actionVariant = TilawaButtonVariant.primary,
    this.trailing,
    this.progress,
    this.trackProgress,
    this.showChevron = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Quiet label above [title] (e.g. "Current wird").
  final String? eyebrow;
  final String title;
  final String? subtitle;

  /// Soft status pill under the title (e.g. "Day 1 of 30").
  final String? statusChipLabel;

  /// Supporting body line (remaining pages, empty copy, …).
  final String? detail;

  /// Featured CTA under the copy (empty / continue / open hub).
  final String? actionLabel;

  /// Use [TilawaButtonVariant.outline] when today’s wird is already done.
  final TilawaButtonVariant actionVariant;
  final Widget? trailing;

  /// Optional 0–100 overall plan progress for the green micro-ring.
  final int? progress;

  /// Optional 0–1 today's wird track under the copy.
  final double? trackProgress;

  /// Quiet trailing chevron — suppressed when [actionLabel] is set (CTA is
  /// the affordance).
  final bool showChevron;
  final String? semanticLabel;

  static const double _onPrimaryMuted = 0.82;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final screenTokens = theme.componentTokens.homeScreen;
    final Color accent = screenTokens.homePrayerHeroAccent;
    final Color onAccent = colorScheme.onPrimary;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final Color surface = HomeFeaturePastel.featuredHabitSurface(
      accent: accent,
      colorScheme: colorScheme,
    );
    final Color mutedOnAccent = onAccent.withValues(alpha: _onPrimaryMuted);
    final TextStyle? bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: mutedOnAccent,
      height: isArabic ? tokens.textHeightLoose : 1.45,
    );
    final bool showTrailingChevron = showChevron && actionLabel == null;
    final bool outlineCta = actionVariant == TilawaButtonVariant.outline;

    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      stateLayerColor: onAccent,
      color: surface,
      tier: HomeDashboardElevationTier.primary,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceSmall,
              children: [
                HomeDashboardIconWell(
                  accent: onAccent,
                  fillAlpha: HomeFeaturePastel.solidIconWellFillAlpha,
                  extent: tokens.iconBadgeSize,
                  child: Icon(
                    icon,
                    size: tokens.iconSizeLarge,
                    color: accent,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      if (eyebrow case final String eyebrowText)
                        Text(
                          eyebrowText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: mutedOnAccent,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onAccent,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (statusChipLabel case final String chipLabel)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TilawaStatusChip(
                            label: chipLabel,
                            backgroundColor: onAccent.withValues(alpha: 0.18),
                            foregroundColor: onAccent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (progress case final int value)
                  _KhatmaProgressRing(
                    progress: value,
                    accent: onAccent,
                  ),
                if (trailing case final Widget trailingWidget) trailingWidget,
                if (showTrailingChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: mutedOnAccent,
                    size: tokens.iconSizeLarge,
                  ),
              ],
            ),
            if (subtitle case final String bodyText)
              Text(
                bodyText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle,
              ),
            if (detail case final String detailText)
              Text(
                detailText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle,
              ),
            if (trackProgress case final double todayFraction)
              _KhatmaTodayTrack(
                progress: todayFraction,
                track: onAccent.withValues(alpha: 0.28),
                fill: onAccent,
              ),
            if (actionLabel case final String cta)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: tokens.spaceExtraSmall,
                ),
                child: TilawaButton(
                  text: cta,
                  variant: outlineCta
                      ? TilawaButtonVariant.outline
                      : TilawaButtonVariant.primary,
                  isFullWidth: true,
                  backgroundColor: outlineCta ? null : onAccent,
                  foregroundColor: outlineCta ? onAccent : accent,
                  borderColor: onAccent,
                  onPressed: onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KhatmaTodayTrack extends StatelessWidget {
  const _KhatmaTodayTrack({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double clamped = progress.clamp(0.0, 1.0);
    final double trackHeight = tokens.borderWidthThin * 4;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusPill(trackHeight)),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: trackHeight,
        backgroundColor: track,
        color: fill,
      ),
    );
  }
}

class _KhatmaProgressRing extends StatelessWidget {
  const _KhatmaProgressRing({
    required this.progress,
    required this.accent,
  });

  final int progress;

  /// Ring + label color (on-primary on a solid primary card).
  final Color accent;

  static const double _trackAlpha = 0.28;
  static const double _discAlpha = 0.22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double size = tokens.iconBadgeSize + tokens.spaceSmall;
    final double stroke = tokens.spaceSmall;
    final double inset = tokens.spaceExtraSmall;
    final int clampedPct = progress.clamp(0, 100);
    final double clamped = clampedPct / 100;
    final bool isComplete = clampedPct >= 100;

    return Semantics(
      value: '$clampedPct%',
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: _discAlpha),
          ),
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: clamped,
                    strokeWidth: stroke,
                    backgroundColor: accent.withValues(alpha: _trackAlpha),
                    color: accent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(tokens.spaceExtraSmall),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isComplete
                        ? Icon(
                            Icons.check_rounded,
                            color: accent,
                            size: tokens.iconSizeLarge,
                          )
                        : Text(
                            '$clampedPct%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -0.4,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
