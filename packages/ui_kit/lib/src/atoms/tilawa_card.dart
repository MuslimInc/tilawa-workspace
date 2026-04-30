import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A foundational card component with standardized styling.
///
/// Reads default values from [TilawaCardTokens] for consistent
/// radius, border width, and padding across the application.
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
    final tokens = theme.componentTokens.card;

    final double effectiveRadius = borderRadius ?? tokens.borderRadius;

    final Widget content = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? theme.colorScheme.surface)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
          width: borderWidth ?? tokens.borderWidth,
        ),
      ),
      child: Padding(padding: padding ?? tokens.padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: content,
      ),
    );
  }
}
