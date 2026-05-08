import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A standardized tile for selection lists in bottom sheets and dialogs.
///
/// Use for picker options where one item can be selected at a time.
/// Shows a checkmark when selected and applies primary color styling.
class TilawaSelectionTile extends StatelessWidget {
  /// Creates a selection tile.
  const TilawaSelectionTile({
    super.key,
    required this.title,
    this.leading,
    required this.isSelected,
    required this.onTap,
    this.showDivider = true,
  });

  /// The text label to display.
  final String title;

  /// Optional leading widget (icon, color circle, flag, etc.).
  final Widget? leading;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// Whether to show a divider below the tile.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;

    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
    );

    return Column(
      children: [
        Material(
          color: isSelected
              ? Color.alphaBlend(
                  colorScheme.primary.withValues(
                    alpha: tokens.tileIconContainerOpacity * 3,
                  ),
                  colorScheme.surface,
                )
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: tokens.tileContentPadding,
              child: Row(
                spacing: tokens.tileItemGap,
                children: [
                  if (leading != null) leading!,
                  Expanded(child: Text(title, style: textStyle)),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      color: colorScheme.primary,
                      size: tokens.tileTrailingSize,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: tokens.tileDividerPadding,
            child: Divider(
              height: tokens.tileDividerHeight,
              thickness: tokens.tileDividerThickness,
              color: colorScheme.outlineVariant.withValues(
                alpha: tokens.tileDividerOpacity,
              ),
            ),
          ),
      ],
    );
  }
}
