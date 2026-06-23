import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_box.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';

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
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final TilawaSemanticTint semanticTint;
  final int tintIndex;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: tileFill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: tokens.borderWidthThin,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceExtraSmall,
                vertical: tokens.spaceSmall,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TilawaIconBox(
                    icon: icon ?? Icons.circle_outlined,
                    size: tokens.iconSizeMedium,
                    padding: tokens.spaceSmall,
                    variant: TilawaIconBoxVariant.tinted,
                    semanticTint: semanticTint,
                    child: iconWidget,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
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
