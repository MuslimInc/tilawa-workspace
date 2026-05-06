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
    final colorScheme = theme.colorScheme;
    final color = foregroundColor ?? colorScheme.onSurfaceVariant;

    return TilawaChip(
      label: label,
      icon: icon,
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerLow,
      foregroundColor: color,
      borderColor:
          borderColor ??
          colorScheme.outlineVariant.withValues(
            alpha: designTokens.opacityMedium,
          ),
      padding: componentTokens.compactPadding,
      borderRadius: componentTokens.roundedRadius,
      iconSize: designTokens.iconSizeSmall,
      textStyle: theme.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
