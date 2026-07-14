import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/tilawa_interactive_surface.dart';

/// A standardized tile for selection lists in bottom sheets and dialogs.
///
/// Use for picker options where one item can be selected at a time.
/// Shows a checkmark and bolder label when selected; row fill stays neutral.
class TilawaSelectionTile extends StatelessWidget {
  /// Creates a selection tile.
  const TilawaSelectionTile({
    super.key,
    required this.title,
    this.leading,
    required this.isSelected,
    required this.onTap,
    this.showDivider = true,
    this.enabled = true,
    this.fontFamily,
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

  /// Whether the tile is interactive.
  final bool enabled;

  /// Optional font family override (e.g. native script for language labels).
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.settingsGroup;
    final designTokens = theme.tokens;

    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: colorScheme.onSurface,
      fontFamily: fontFamily,
    );

    return Column(
      children: [
        TilawaInteractiveSurface(
          onTap: onTap,
          enabled: enabled,
          // fix: Accessibility — single-select list item state.
          selected: isSelected,
          semanticLabel: title,
          child: ColoredBox(
            color: isSelected
                ? tokens.selectionTileSelectedBackgroundColor
                : Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: designTokens.minInteractiveDimension,
              ),
              child: Padding(
                padding: tokens.tileContentPadding,
                child: Row(
                  spacing: tokens.tileItemGap,
                  children: [
                    ?leading,
                    Expanded(child: Text(title, style: textStyle)),
                    if (isSelected)
                      Icon(
                        TilawaIcons.check,
                        color: colorScheme.primary,
                        size: tokens.tileTrailingSize,
                      ),
                  ],
                ),
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
              color: tokens.selectionTileDividerColor,
            ),
          ),
      ],
    );
  }
}
