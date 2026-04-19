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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            theme.colorScheme.surface.withValues(alpha: tokens.opacityGlass),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              borderColor ??
              theme.colorScheme.outline.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.spaceSmall,
        children: [
          if (icon != null) Icon(icon, size: tokens.iconSizeSmall, color: color),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
