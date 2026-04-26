import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_chip.dart';

class MetadataChip extends StatelessWidget {
  const MetadataChip({
    super.key,
    required this.label,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.chip;
    final color = foregroundColor ?? theme.colorScheme.onSurface;

    return TilawaChip(
      label: label,
      icon: icon,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: color,
      borderColor: borderColor,
      padding: EdgeInsets.zero,
      borderRadius: componentTokens.roundedRadius,
      iconSize: designTokens.iconSizeSmall,
      textStyle: theme.textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}
