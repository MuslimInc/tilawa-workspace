import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
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

    return TilawaInteractiveSurface(
      onTap: onTap,
      borderRadius: borderRadius,
      semanticLabel: label,
      stateLayerColor: iconAccent,
      child: DecoratedBox(
        decoration: HomeDashboardElevatedSurface.decoration(
          context,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomePrimaryActionIconWell(
                icon: icon,
                iconAccent: iconAccent,
              ),
              SizedBox(
                height: tokens.spaceSmall + tokens.spaceExtraSmall,
              ),
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
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePrimaryActionIconWell extends StatelessWidget {
  const _HomePrimaryActionIconWell({
    required this.icon,
    required this.iconAccent,
  });

  final Widget icon;
  final Color iconAccent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double iconBoxSize = tokens.iconSizeLarge + tokens.spaceMedium;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        color: iconAccent.withValues(alpha: 0.10),
      ),
      child: SizedBox(
        width: iconBoxSize,
        height: iconBoxSize,
        child: Center(child: icon),
      ),
    );
  }
}
