import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Primary action tile for the Home dashboard.
class HomePrimaryActionTile extends StatelessWidget {
  const HomePrimaryActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.progress,
    required this.onTap,
    required this.accent,
    this.surfaceColor,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final Widget icon;
  final String label;
  final String? subtitle;

  /// Optional 0–1 goal-gradient cue under the subtitle. Null or ≤0 hides it.
  final double? progress;
  final VoidCallback onTap;
  final Color accent;

  /// Optional resting fill; defaults to elevated [ColorScheme.surface].
  final Color? surfaceColor;

  /// Quiet secondary path (e.g. Athkar library). Nested control at card bottom.
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color surface = surfaceColor ?? colorScheme.surface;
    final bool isPrimarySurface = surface == colorScheme.primary;
    final Color foreground = isPrimarySurface
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final Color secondaryForeground = isPrimarySurface
        ? colorScheme.onPrimary.withValues(alpha: 0.85)
        : HomeDashboardSection.secondaryTextColor(context);
    final Color chrome = isPrimarySurface ? colorScheme.onPrimary : accent;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final String? subtitleText = subtitle;
    final double? clampedProgress = progress?.clamp(0.0, 1.0);
    final bool showProgress = clampedProgress != null && clampedProgress > 0;
    final String? secondary = secondaryLabel;
    final bool showSecondary =
        secondary != null && secondary.isNotEmpty && onSecondaryTap != null;

    final Widget titleCluster = Column(
      spacing: tokens.spaceSmall,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        if (subtitleText != null && subtitleText.isNotEmpty)
          Text(
            subtitleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryForeground,
              height: 1.4,
            ),
          ),
      ],
    );

    final Widget body = Column(
      spacing: tokens.spaceLarge,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeDashboardIconWell(
          accent: chrome,
          fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
          extent: tokens.iconBoxSize,
          child: icon,
        ),
        titleCluster,
        if (showProgress)
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: tokens.progressHeight,
              backgroundColor: chrome.withValues(alpha: 0.12),
              color: chrome,
            ),
          ),
      ],
    );

    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: label,
      stateLayerColor: chrome,
      color: surface,
      tier: HomeDashboardElevationTier.primary,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: showSecondary
            ? Column(
                spacing: tokens.spaceMedium,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: body),
                  TilawaButton(
                    text: secondary,
                    variant: TilawaButtonVariant.secondary,
                    size: TilawaButtonSize.small,
                    isFullWidth: true,
                    backgroundColor: Color.alphaBlend(
                      chrome.withValues(
                        alpha: HomeFeaturePastel.iconWellFillAlpha,
                      ),
                      surface,
                    ),
                    foregroundColor: chrome,
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      color: chrome,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: onSecondaryTap,
                  ),
                ],
              )
            : body,
      ),
    );
  }
}
