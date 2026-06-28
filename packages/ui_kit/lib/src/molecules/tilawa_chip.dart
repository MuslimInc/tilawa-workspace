import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';

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
    final effectiveBorderColor =
        borderColor ?? componentTokens.defaultBorderColor;

    final double resolvedRadius =
        borderRadius ??
        (onTap != null
            ? designTokens.resolveRadius(
                family: TilawaRadiusFamily.chip,
                height: _chipPaintedHeight(
                  context,
                  chipTokens: componentTokens,
                  theme: theme,
                  padding: padding,
                  iconSize: iconSize,
                  icon: icon,
                  showLabel: showLabel,
                  textStyle: textStyle,
                ),
              )
            : designTokens.resolveRadius(
                family: TilawaRadiusFamily.decorative,
              ));

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(resolvedRadius),
      side: BorderSide(
        color: effectiveBorderColor,
        width: componentTokens.borderWidth,
      ),
    );

    // The visible chip body — sized to its content via Row(mainAxisSize: min).
    // Label is [Flexible] so ellipsis works when the chip sits in a bounded
    // parent (e.g. equal-width override type columns).
    final Widget chipRow = Row(
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
    );

    final Widget content = Container(
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
      child: chipRow,
    );

    if (onTap == null) {
      return !showLabel && icon != null
          ? Semantics(label: label, child: content)
          : content;
    }

    // fix: Accessibility — tappable chips paint at their intrinsic content
    // size (so dense layouts stay dense) while reserving a 48 dp tap-area
    // around the painted pill. The outer Center collapses unbounded parents
    // to the chip's intrinsic size; the Container's alignment lets the
    // painted Material keep that intrinsic size while the box itself extends
    // to at least 48 dp for the hit target. Static (label) chips bypass this
    // branch entirely.
    // Explicit button role / label avoids MergeSemantics (engine merge bugs).
    // Background + border are painted by the Container inside [content]; the
    // interactive surface adds state-layer press, focus ring, and haptics
    // and its own semantics are excluded so the outer Semantics owns the node.
    final Widget paintedChip = TilawaInteractiveSurface(
      onTap: onTap,
      button: false,
      borderRadius: BorderRadius.circular(resolvedRadius),
      child: content,
    );

    // Shrink-wrap both axes so chips stay compact inside [Wrap] and other
    // loose parents. The 48 dp minimum keeps the hit-target accessible.
    return Semantics(
      button: true,
      label: label,
      selected: semanticsSelected,
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMeMuslimMinInteractiveDimension,
              minHeight: kMeMuslimMinInteractiveDimension,
            ),
            child: paintedChip,
          ),
        ),
      ),
    );
  }
}

double _chipPaintedHeight(
  BuildContext context, {
  required TilawaChipTokens chipTokens,
  required ThemeData theme,
  EdgeInsetsGeometry? padding,
  double? iconSize,
  IconData? icon,
  bool showLabel = true,
  TextStyle? textStyle,
}) {
  final EdgeInsets resolvedPadding = (padding ?? chipTokens.padding).resolve(
    Directionality.of(context),
  );
  final TextStyle effectiveTextStyle =
      textStyle ?? theme.textTheme.labelLarge ?? const TextStyle(fontSize: 14);
  final double lineHeight =
      effectiveTextStyle.fontSize! * (effectiveTextStyle.height ?? 1.2);
  final double iconDimension = iconSize ?? chipTokens.iconSize;
  final double contentHeight = switch ((icon != null, showLabel)) {
    (true, true) => iconDimension > lineHeight ? iconDimension : lineHeight,
    (true, false) => iconDimension,
    _ => lineHeight,
  };
  return resolvedPadding.vertical + contentHeight;
}
