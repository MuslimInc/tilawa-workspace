import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Premium primary action tile for the Home dashboard.
class HomePrimaryActionTile extends StatelessWidget {
  const HomePrimaryActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.goldAccentOnStart = true,
  });

  final Widget icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool goldAccentOnStart;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenTokens = theme.componentTokens.homeScreen;
    final Color iconAccent = screenTokens.homePrayerHeroAccent;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );

    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final double accentRailWidth = tokens.spaceExtraSmall;

    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: label,
      stateLayerColor: iconAccent,
      tier: HomeDashboardElevationTier.primary,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceMedium + accentRailWidth,
          tokens.spaceMedium,
          tokens.spaceMedium,
          tokens.spaceMedium + tokens.spaceExtraSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeDashboardIconWell(
              accent: iconAccent,
              child: icon,
            ),
            SizedBox(height: tokens.spaceMedium + tokens.spaceExtraSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.12,
                letterSpacing: -0.15,
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: HomeDashboardSection.secondaryTextColor(context),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
