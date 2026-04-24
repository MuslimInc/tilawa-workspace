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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: tokens.durationFast,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceSmall + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: background,
            border: Border.all(
              color: selected
                  ? background.withValues(alpha: 0.96)
                  : theme.colorScheme.outline.withValues(
                      alpha: tokens.opacitySubtle,
                    ),
              width: tokens.borderWidthThin,
            ),
            boxShadow: selected
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
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceSmall,
            children: [
              if (icon != null)
                Icon(icon, size: tokens.iconSizeSmall, color: foreground),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
