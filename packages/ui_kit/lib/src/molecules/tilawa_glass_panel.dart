import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaGlassPanel extends StatelessWidget {
  const TilawaGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.glassPanel;
    final effectiveBorderRadius =
        borderRadius ??
        designTokens.radiusExtraLarge + componentTokens.borderRadiusOffset;

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: designTokens.blurGlass,
          sigmaY: designTokens.blurGlass,
        ),
        child: Container(
          width: double.infinity,
          padding: padding ?? componentTokens.padding,
          decoration: BoxDecoration(
            color:
                backgroundColor ??
                theme.colorScheme.surface.withValues(
                  alpha: componentTokens.backgroundOpacity,
                ),
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            border: Border.all(
              color:
                  borderColor ??
                  theme.colorScheme.outline.withValues(
                    alpha: designTokens.opacitySubtle,
                  ),
              width: designTokens.borderWidthThin,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: designTokens.opacitySubtle,
                ),
                blurRadius: designTokens.blurShadow,
                offset: designTokens.shadowOffsetMedium,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
