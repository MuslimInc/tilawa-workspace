import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import 'tilawa_chip.dart';

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
    final tokens = theme.componentTokens.chip;
    final effectiveForeground = foregroundColor ?? theme.colorScheme.onSurface;

    return TilawaChip(
      label: label,
      icon: icon,
      backgroundColor:
          backgroundColor ?? theme.colorScheme.surfaceContainerHigh,
      foregroundColor: effectiveForeground,
      padding: padding ?? tokens.compactPadding,
      borderRadius: tokens.roundedRadius,
      iconSize: tokens.compactIconSize,
      textStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: tokens.statusFontWeight,
        color: effectiveForeground,
        letterSpacing: tokens.statusLetterSpacing,
      ),
    );
  }
}
