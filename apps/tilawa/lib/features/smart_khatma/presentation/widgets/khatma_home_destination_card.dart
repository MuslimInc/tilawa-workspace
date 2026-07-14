import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Smart Khatma home entry — white elevated surface + primary accent chrome.
///
/// Green stays in the accent lane (icon well, chevron, optional progress ring).
/// Full-bleed tinted fills are avoided so the prayer hero stays strongest and
/// Home cards share one calm surface language with the More list.
class KhatmaHomeDestinationCard extends StatelessWidget {
  const KhatmaHomeDestinationCard({
    super.key,
    required this.icon,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.detail,
    this.trailing,
    this.progress,
    this.showChevron = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;

  /// Optional second body line (e.g. today's page range / confirm count).
  final String? detail;
  final Widget? trailing;

  /// Optional 0–100 plan progress for the green micro-ring.
  final int? progress;

  /// Quiet trailing chevron affordance (RTL-mirrored by Flutter icons).
  final bool showChevron;
  final String? semanticLabel;

  static const double _chevronAlpha = 0.72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final screenTokens = theme.componentTokens.homeScreen;
    final Color accent = screenTokens.homePrayerHeroAccent;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final Color surface = HomeFeaturePastel.cardSurface(colorScheme);
    final TextStyle? bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: HomeDashboardSection.secondaryTextColor(context),
      height: isArabic ? tokens.textHeightLoose : 1.45,
    );

    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      stateLayerColor: accent,
      color: surface,
      tier: HomeDashboardElevationTier.primary,
      child: Padding(
        // ~8–12dp shorter than all-sides [spaceLarge] + [spaceMedium] gap.
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
              spacing: tokens.spaceSmall,
              children: [
                HomeDashboardIconWell(
                  accent: accent,
                  fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
                  extent: tokens.iconBadgeSize,
                  child: Icon(
                    icon,
                    size: tokens.iconSizeLarge,
                    color: accent,
                  ),
                ),
                const Spacer(),
                if (progress case final int value)
                  _KhatmaProgressRing(progress: value, accent: accent),
                if (trailing case final Widget trailingWidget) trailingWidget,
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: accent.withValues(alpha: _chevronAlpha),
                    size: tokens.iconSizeLarge,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceExtraSmall,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
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
                    style: bodyStyle?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
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
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double size = tokens.iconBadgeSize;
    final double clamped = (progress.clamp(0, 100)) / 100;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: tokens.borderWidthThin * 3,
              backgroundColor: accent.withValues(alpha: 0.14),
              color: accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$progress%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
