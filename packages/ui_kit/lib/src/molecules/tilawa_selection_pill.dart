import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_chip.dart';

/// Visual treatment for [TilawaSelectionPill].
enum TilawaSelectionPillStyle {
  /// Theme primary-tinted selection (default).
  standard,

  /// Dark selected / light gray idle (Pinterest catalog filters).
  catalog,
}

/// Pill-shaped filter control built on [TilawaChip].
class TilawaSelectionPill extends StatelessWidget {
  const TilawaSelectionPill({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
    this.style = TilawaSelectionPillStyle.standard,
    this.selectedColor,
    this.unselectedColor,
    this.selectedForegroundColor,
    this.unselectedForegroundColor,
    this.elevatedWhenSelected = true,
    this.showLabel = true,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showLabel;
  final TilawaSelectionPillStyle style;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedForegroundColor;
  final Color? unselectedForegroundColor;

  /// When false, selected pills stay flat (Pinterest-style catalog filters).
  final bool elevatedWhenSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.chip;
    final colorScheme = theme.colorScheme;
    final bool isCatalog = style == TilawaSelectionPillStyle.catalog;

    final Color background = selected
        ? (selectedColor ??
              (isCatalog
                  ? componentTokens.catalogSelectedBackgroundColor
                  : componentTokens.selectionSelectedBackgroundColor))
        : (unselectedColor ??
              (isCatalog
                  ? colorScheme.surfaceContainerHigh
                  : componentTokens.selectionUnselectedBackgroundColor));
    final Color foreground = selected
        ? (selectedForegroundColor ??
              (isCatalog
                  ? componentTokens.catalogSelectedForegroundColor
                  : colorScheme.onPrimary))
        : (unselectedForegroundColor ??
              (isCatalog ? colorScheme.onSurface : colorScheme.onSurface));

    return TilawaChip(
      label: label,
      icon: icon,
      onTap: onTap,
      showLabel: showLabel,
      semanticsSelected: selected,
      backgroundColor: background,
      foregroundColor: foreground,
      borderRadius: designTokens.resolveRadius(
        family: TilawaRadiusFamily.selection,
      ),
      borderColor: selected
          ? background
          : (isCatalog
                ? Colors.transparent
                : theme.colorScheme.outline.withValues(
                    alpha: designTokens.opacitySubtle,
                  )),
      padding: componentTokens.padding,
      showShadow: selected && elevatedWhenSelected && !isCatalog,
      shadowColor: background,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: componentTokens.selectionFontWeight,
      ),
    );
  }
}
