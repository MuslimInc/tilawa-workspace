import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';

class SelectionPill extends StatelessWidget {
  const SelectionPill({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    this.selectedForegroundColor,
    this.unselectedForegroundColor,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedForegroundColor;
  final Color? unselectedForegroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final background = selected
        ? (selectedColor ?? theme.colorScheme.primary)
        : (unselectedColor ??
              theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: tokens.opacityMedium,
              ));
    final foreground = selected
        ? (selectedForegroundColor ?? theme.colorScheme.onPrimary)
        : (unselectedForegroundColor ?? theme.colorScheme.onSurface);
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected
            ? background
            : theme.colorScheme.outline.withValues(alpha: tokens.opacitySubtle),
        width: tokens.borderWidthThin,
      ),
    );

    return Material(
      color: Colors.transparent,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceSmall + tokens.spaceTiny,
          ),
          decoration: ShapeDecoration(
            shape: shape,
            color: background,
            shadows: selected
                ? [
                    BoxShadow(
                      color: background.withValues(alpha: tokens.opacityMedium),
                      blurRadius: tokens.blurShadow,
                      offset: tokens.shadowOffsetSmall,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: .min,
            spacing: tokens.spaceSmall,
            children: [
              if (icon != null)
                Icon(icon, size: tokens.iconSizeSmall, color: foreground),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: .w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
