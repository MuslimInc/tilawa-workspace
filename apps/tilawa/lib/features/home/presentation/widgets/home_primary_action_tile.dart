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
    required this.onTap,
    required this.accent,
  });

  final Widget icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color surface = colorScheme.surface;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final String? subtitleText = subtitle;

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
          ],
        ),
      ),
    );
  }
}
