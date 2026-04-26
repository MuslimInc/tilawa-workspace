import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

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
    final tokens = theme.tokens;
    final color = foregroundColor ?? theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: .min,
      spacing: tokens.spaceSmall,
      children: [
        if (icon != null) Icon(icon, size: tokens.iconSizeSmall, color: color),
        Text(label, maxLines: 1, overflow: .ellipsis),
      ],
    );
  }
}
