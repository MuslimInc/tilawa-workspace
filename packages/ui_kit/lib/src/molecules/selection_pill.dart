import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_chip.dart';

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
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.chip;
    final background = selected
        ? (selectedColor ?? theme.colorScheme.primary)
        : (unselectedColor ??
              theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: designTokens.opacityMedium,
              ));
    final foreground = selected
        ? (selectedForegroundColor ?? theme.colorScheme.onPrimary)
        : (unselectedForegroundColor ?? theme.colorScheme.onSurface);

    return TilawaChip(
      label: label,
      icon: icon,
      onTap: onTap,
      backgroundColor: background,
      foregroundColor: foreground,
      borderColor: selected
          ? background
          : theme.colorScheme.outline.withValues(
              alpha: designTokens.opacitySubtle,
            ),
      borderRadius: componentTokens.pillRadius,
      padding: componentTokens.padding,
      showShadow: selected,
      shadowColor: background,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: componentTokens.selectionFontWeight,
      ),
    );
  }
}
