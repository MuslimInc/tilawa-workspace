import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_box.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import '../foundation/tilawa_interactive_surface.dart';

/// Talabat-style category tile — warm tinted square, icon, two-line label.
class TilawaFeatureCategoryTile extends StatelessWidget {
  const TilawaFeatureCategoryTile({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.semanticTint = TilawaSemanticTint.neutral,
    this.tintIndex = 0,
    this.iconBoxVariant = TilawaIconBoxVariant.tinted,
    this.iconBoxBackgroundColor,
    this.iconColor,
    this.tileBorderOpacity = 0.35,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final TilawaSemanticTint semanticTint;
  final int tintIndex;
  final TilawaIconBoxVariant iconBoxVariant;
  final Color? iconBoxBackgroundColor;
  final Color? iconColor;
  final double tileBorderOpacity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final Color tileFill =
        backgroundColor ?? cardTokens.featureCategoryTileTint(tintIndex);
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: TilawaInteractiveSurface(
          onTap: onTap,
          button: false,
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tileFill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: tileBorderOpacity,
                ),
                width: tokens.borderWidthThin,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceExtraSmall,
                vertical: tokens.spaceSmall - tokens.borderWidthThin,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TilawaIconBox(
                    icon: icon ?? Icons.circle_outlined,
                    size: tokens.iconSizeMedium,
                    padding: tokens.spaceSmall,
                    variant: iconBoxVariant,
                    semanticTint: semanticTint,
                    backgroundColor: iconBoxBackgroundColor,
                    iconColor: iconColor,
                    child: iconWidget,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
