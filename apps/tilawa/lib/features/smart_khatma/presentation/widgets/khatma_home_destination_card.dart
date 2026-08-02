import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Smart Khatma home entry — neutral lift + focused green progress/CTA.
///
/// Strong green is reserved for the icon glyph, progress, and single CTA so the
/// daily habit remains scannable without competing with the Home hero.
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

  final Widget? trailing;

  /// Optional 0–100 overall plan progress for the compact green status pill.
  final int? progress;

  /// Optional 0–1 today's wird track under the copy.
  final double? trackProgress;

  /// Quiet trailing chevron — suppressed when [actionLabel] is set (CTA is
  /// the affordance).
  final bool showChevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final screenTokens = theme.componentTokens.homeScreen;
    final Color accent = screenTokens.homePrayerHeroAccent;
    final Color onAccent = colorScheme.onPrimary;
    final Color foreground = colorScheme.onSurface;
    final Color mutedForeground = colorScheme.onSurfaceVariant;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final Color surface = HomeFeaturePastel.cardSurface(colorScheme);
    final LinearGradient headerGradient =
        HomeFeaturePastel.featuredHeaderGradient(
          accent: accent,
          colorScheme: colorScheme,
        );
    final TextStyle? bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: mutedForeground,
      height: isArabic ? tokens.textHeightLoose : 1.45,
    );
    final bool showTrailingChevron = showChevron && actionLabel == null;
    final BorderRadius headerRadius = BorderRadius.vertical(
      top: Radius.circular(radius),
    );

    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      stateLayerColor: accent,
      color: surface,
      tier: HomeDashboardElevationTier.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: headerGradient,
              borderRadius: headerRadius,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spaceLarge,
                tokens.spaceMedium,
                tokens.spaceLarge,
                tokens.spaceMedium,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceSmall,
                children: [
                  HomeDashboardIconWell(
                    accent: surface,
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
                              color: mutedForeground,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (statusChipLabel != null || progress != null)
                          Wrap(
                            spacing: tokens.spaceExtraSmall,
                            runSpacing: tokens.spaceExtraSmall,
                            children: [
                              if (statusChipLabel case final String chipLabel)
                                TilawaStatusChip(
                                  label: chipLabel,
                                  backgroundColor: surface,
                                  foregroundColor: foreground,
                                ),
                              if (progress case final int value)
                                TilawaStatusChip(
                                  label: '${value.clamp(0, 100)}%',
                                  backgroundColor: accent,
                                  foregroundColor: onAccent,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (trailing case final Widget trailingWidget) trailingWidget,
                  if (showTrailingChevron)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: mutedForeground,
                      size: tokens.iconSizeLarge,
                    ),
                ],
              ),
            ),
          ),
          Padding(
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
                    track: accent.withValues(alpha: 0.18),
                    fill: accent,
                  ),
                if (actionLabel case final String cta)
                  TilawaButton(
                    text: cta,
                    variant: TilawaButtonVariant.primary,
                    isFullWidth: true,
                    backgroundColor: accent,
                    foregroundColor: onAccent,
                    onPressed: onTap,
                  ),
              ],
            ),
          ),
        ],
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
