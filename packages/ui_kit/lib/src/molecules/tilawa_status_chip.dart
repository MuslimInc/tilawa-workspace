import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';

/// A standardized status chip used for badges and status indicators.
class TilawaStatusChip extends StatelessWidget {
  const TilawaStatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.padding,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: tokens.spaceExtraSmall,
            vertical: tokens.spaceTiny,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.spaceExtraSmall,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: tokens.iconSizeSmall - 2,
              color: foregroundColor ?? theme.colorScheme.onSurface,
            ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: foregroundColor ?? theme.colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
