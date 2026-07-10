import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home dashboard surface — flat white card with hairline border.
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
    final screenTokens = theme.componentTokens.homeScreen;
    final tokens = theme.tokens;
    final double effectiveRadius =
        borderRadius ?? tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final Color cardBorder = Color.alphaBlend(
      screenTokens.homePrayerHeroBorder.withValues(alpha: 0.72),
      theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stretchVertically =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final Widget content = stretchVertically
            ? SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: child,
              )
            : child;

        final Widget card = !useFeaturedGradient
            ? TilawaCard(
                padding: padding,
                backgroundColor:
                    backgroundColor ?? screenTokens.homeContentSheetSurface,
                borderColor: cardBorder,
                borderRadius: effectiveRadius,
                surface: surface,
                onTap: onTap,
                expandHeight: stretchVertically,
                child: content,
              )
            : TilawaCard(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                borderColor: cardBorder,
                borderRadius: effectiveRadius,
                surface: surface,
                onTap: onTap,
                expandHeight: stretchVertically,
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
                    child: content,
                  ),
                ),
              );

        if (!stretchVertically) {
          return card;
        }

        return SizedBox(
          height: constraints.maxHeight,
          width: double.infinity,
          child: card,
        );
      },
    );
  }
}
