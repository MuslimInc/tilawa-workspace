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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color surface = surfaceColor ?? colorScheme.surface;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final String? subtitleText = subtitle;
    final double? clampedProgress = progress?.clamp(0.0, 1.0);
    final bool showProgress = clampedProgress != null && clampedProgress > 0;

    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: label,
      stateLayerColor: accent,
      color: surface,
      tier: HomeDashboardElevationTier.primary,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeDashboardIconWell(
              accent: accent,
              fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
              extent: tokens.iconBoxSize,
              child: icon,
            ),
            SizedBox(height: tokens.spaceMedium),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            if (subtitleText != null && subtitleText.isNotEmpty) ...[
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                subtitleText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: HomeDashboardSection.secondaryTextColor(context),
                  height: 1.35,
                ),
              ),
            ],
            if (showProgress) ...[
              SizedBox(height: tokens.spaceSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  minHeight: tokens.progressHeight,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  color: accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
