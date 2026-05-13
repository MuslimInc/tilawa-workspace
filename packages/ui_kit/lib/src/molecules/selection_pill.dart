import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_chip.dart';

/// Pill-shaped filter control built on [TilawaChip].
class TilawaSelectionPill extends StatelessWidget {
  const TilawaSelectionPill({
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
        ? (selectedColor ?? componentTokens.selectionSelectedBackgroundColor)
        : (unselectedColor ??
              componentTokens.selectionUnselectedBackgroundColor);
    final foreground = selected
        ? (selectedForegroundColor ?? theme.colorScheme.onPrimaryContainer)
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

/// Deprecated. Use [TilawaSelectionPill] instead.
@Deprecated('Use TilawaSelectionPill instead')
typedef SelectionPill = TilawaSelectionPill;
