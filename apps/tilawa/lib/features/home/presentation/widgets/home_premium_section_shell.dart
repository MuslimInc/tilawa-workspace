import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Gradient-bordered shell for premium Home dashboard sections.
class HomePremiumSectionShell extends StatelessWidget {
  const HomePremiumSectionShell({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final colorScheme = theme.colorScheme;
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: cardTokens.backgroundGradient(),
        border: Border.all(
          color: cardTokens.borderColor,
          width: tokens.borderWidthThin,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: tokens.opacityShadow,
            ),
            offset: tokens.shadowOffsetSmall,
            blurRadius: tokens.spaceSmall,
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(tokens.spaceMedium),
        child: child,
      ),
    );
  }
}
