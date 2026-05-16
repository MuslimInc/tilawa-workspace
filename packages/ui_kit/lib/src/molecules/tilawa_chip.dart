import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaChip extends StatelessWidget {
  const TilawaChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.semanticsSelected,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.textStyle,
    this.showShadow = false,
    this.shadowColor,
    this.showLabel = true,
  });

  final String label;
  final IconData? icon;

  /// When false and [icon] is non-null, only the icon is shown; [label] is
  /// still used for accessibility. If [icon] is null, the label is always
  /// shown.
  final bool showLabel;
  final VoidCallback? onTap;

  /// When non-null, merged into tap [Semantics] for selection state
  /// (e.g. [TilawaSelectionPill]).
  final bool? semanticsSelected;
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
    final colorScheme = theme.colorScheme;
    final componentTokens = theme.componentTokens.chip;
    final designTokens = theme.tokens;
    final effectiveBackground =
        backgroundColor ?? componentTokens.backgroundColor;
    final effectiveForeground = foregroundColor ?? colorScheme.onSurfaceVariant;
    final effectiveRadius = borderRadius ?? componentTokens.roundedRadius;
    final effectiveBorderColor =
        borderColor ?? componentTokens.defaultBorderColor;

    // Tappable chips honor the Tilawa 44 dp interactive minimum. At that size
    // the dense 8 dp corner radius reads as a square button, so the corner
    // rule shifts: pill rounding (radius = height / 2). Icon-only tappable
    // chips become 44 dp circles for free since width == height. Static
    // (label) chips keep their dense rounding.
    final double resolvedRadius = onTap != null
        ? kTilawaMinInteractiveDimension / 2
        : effectiveRadius;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(resolvedRadius),
      side: BorderSide(
        color: effectiveBorderColor,
        width: componentTokens.borderWidth,
      ),
    );

    final Widget content = Container(
      padding: padding ?? componentTokens.padding,
      decoration: ShapeDecoration(
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
      child: Center(
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
            if (showLabel || icon == null)
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
      ),
    );

    if (onTap == null) {
      return !showLabel && icon != null
          ? Semantics(label: label, child: content)
          : content;
    }

    // fix: Accessibility — tappable chips enforce the Tilawa 44 dp minimum so
    // the painted body and the ink splash share the same bounds; static
    // (label) chips stay dense. Explicit button role / label avoids
    // MergeSemantics (engine merge bugs).
    return Semantics(
      button: true,
      label: label,
      selected: semanticsSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kTilawaMinInteractiveDimension,
          minHeight: kTilawaMinInteractiveDimension,
        ),
        child: Material(
          color: effectiveBackground,
          shape: shape,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: content,
          ),
        ),
      ),
    );
  }
}
