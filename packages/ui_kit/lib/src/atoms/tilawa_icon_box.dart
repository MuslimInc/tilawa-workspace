import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';

/// A standardized container for icons with background styling.
class TilawaIconBox extends StatelessWidget {
  const TilawaIconBox({
    super.key,
    required this.icon,
    this.size,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
    this.child,
  });

  final IconData icon;
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? borderRadius;
  final double? padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final double effectiveSize = size ?? tokens.iconSizeLarge;
    final double effectivePadding = padding ?? tokens.spaceSmall;

    return Container(
      padding: EdgeInsets.all(effectivePadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(
          borderRadius ?? tokens.radiusMedium,
        ),
      ),
      child:
          child ??
          Icon(
            icon,
            size: effectiveSize,
            color: iconColor ?? theme.colorScheme.onSurface,
          ),
    );
  }
}
