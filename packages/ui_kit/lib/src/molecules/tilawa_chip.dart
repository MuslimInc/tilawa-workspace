import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaChip extends StatelessWidget {
  const TilawaChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.textStyle,
    this.showShadow = false,
    this.shadowColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? iconSize;
  final TextStyle? textStyle;
  final bool showShadow;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.chip;
    final designTokens = theme.tokens;
    final effectiveBackground =
        backgroundColor ?? theme.colorScheme.surfaceContainerHigh;
    final effectiveForeground = foregroundColor ?? theme.colorScheme.onSurface;
    final effectiveRadius = borderRadius ?? componentTokens.roundedRadius;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(effectiveRadius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!, width: componentTokens.borderWidth),
    );

    final content = Container(
      padding: padding ?? componentTokens.padding,
      decoration: ShapeDecoration(
        color: effectiveBackground,
        shape: shape,
        shadows: showShadow
            ? [
                BoxShadow(
                  color: (shadowColor ?? effectiveBackground).withValues(
                    alpha: componentTokens.selectedShadowOpacity,
                  ),
                  blurRadius: componentTokens.selectedShadowBlur,
                  offset: designTokens.shadowOffsetSmall,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: componentTokens.contentGap,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: iconSize ?? componentTokens.iconSize,
              color: effectiveForeground,
            ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  textStyle ??
                  theme.textTheme.labelLarge?.copyWith(
                    color: effectiveForeground,
                  ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      shape: shape,
      child: InkWell(onTap: onTap, customBorder: shape, child: content),
    );
  }
}
