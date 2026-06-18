import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home dashboard surface — white elevated card with thin shadow.
class HomeDashboardCard extends StatelessWidget {
  const HomeDashboardCard({
    super.key,
    required this.child,
    this.padding,
    this.useFeaturedGradient = false,
    this.backgroundColor,
    this.borderRadius,
    this.surface = TilawaCardSurface.raised,
    this.onTap,
    this.splashColor,
    this.highlightColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// When true, paints the TripGlide card surface from dashboard card tokens.
  final bool useFeaturedGradient;
  final Color? backgroundColor;
  final double? borderRadius;
  final TilawaCardSurface surface;
  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final tokens = theme.tokens;
    final double effectiveRadius =
        borderRadius ?? tokens.resolveRadius(family: TilawaRadiusFamily.hero);

    if (!useFeaturedGradient) {
      return TilawaCard(
        padding: padding,
        backgroundColor: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: effectiveRadius,
        borderWidth: 0,
        surface: surface,
        onTap: onTap,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: child,
      );
    }

    return TilawaCard(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      borderRadius: effectiveRadius,
      borderWidth: 0,
      surface: surface,
      onTap: onTap,
      splashColor: splashColor ?? cardTokens.splashColor,
      highlightColor: highlightColor ?? cardTokens.highlightColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(effectiveRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              cardTokens.gradientStart,
              cardTokens.gradientEnd,
            ],
          ),
        ),
        child: Padding(
          padding: padding ?? theme.componentTokens.card.padding,
          child: child,
        ),
      ),
    );
  }
}
