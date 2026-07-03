import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
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
    final Color accentRailColor = colorScheme.tertiary.withValues(
      alpha: tokens.opacitySubtle * 4,
    );
    final double accentRailWidth = tokens.spaceExtraSmall;

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
        child: Stack(
          children: [
            PositionedDirectional(
              start: goldAccentOnStart ? 0 : null,
              end: goldAccentOnStart ? null : 0,
              top: 0,
              bottom: 0,
              child: _HomePrimaryActionAccentRail(
                color: accentRailColor,
                width: accentRailWidth,
                radius: radius,
                onStart: goldAccentOnStart,
              ),
            ),
            Padding(
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
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.92,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePrimaryActionAccentRail extends StatelessWidget {
  const _HomePrimaryActionAccentRail({
    required this.color,
    required this.width,
    required this.radius,
    required this.onStart,
  });

  final Color color;
  final double width;
  final double radius;
  final bool onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: onStart
            ? BorderRadiusDirectional.horizontal(
                start: Radius.circular(radius),
              )
            : BorderRadiusDirectional.horizontal(
                end: Radius.circular(radius),
              ),
      ),
    );
  }
}
