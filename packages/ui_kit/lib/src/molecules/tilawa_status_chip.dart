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
    this.showLabel = true,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.chip;
    final colorScheme = theme.colorScheme;
    final effectiveForeground = foregroundColor ?? colorScheme.onSurfaceVariant;

    return TilawaChip(
      label: label,
      icon: icon,
      backgroundColor: backgroundColor ?? tokens.backgroundColor,
      foregroundColor: effectiveForeground,
      padding: padding ?? tokens.compactPadding,
      borderRadius: tokens.roundedRadius,
      iconSize: tokens.compactIconSize,
      showLabel: showLabel,
      textStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: tokens.statusFontWeight,
        color: effectiveForeground,
        letterSpacing: tokens.statusLetterSpacing,
      ),
    );
  }
}
