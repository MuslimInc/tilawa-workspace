import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';

/// A foundational card component with standardized styling.
class TilawaCard extends StatelessWidget {
  const TilawaCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final Widget content = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? theme.colorScheme.surface)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? tokens.radiusLarge),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
          width: borderWidth ?? tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(tokens.spaceMedium),
        child: child,
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius ?? tokens.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? tokens.radiusLarge),
        child: content,
      ),
    );
  }
}
