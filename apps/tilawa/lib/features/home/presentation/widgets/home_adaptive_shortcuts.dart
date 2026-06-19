import 'package:flutter/material.dart';

import '../../domain/entities/home_layout_mode.dart';
import 'home_shortcut_entry.dart';
import 'home_shortcut_grid_view.dart';

/// Renders [gridEntries] as a grid or falls back to [listChild] in list mode.
class HomeAdaptiveShortcuts extends StatelessWidget {
  const HomeAdaptiveShortcuts({
    super.key,
    required this.layoutMode,
    required this.gridEntries,
    required this.listChild,
    this.gridColumnCount,
  });

  final HomeLayoutMode layoutMode;
  final List<HomeShortcutEntry> gridEntries;
  final Widget listChild;
  final int? gridColumnCount;

  @override
  Widget build(BuildContext context) {
    if (layoutMode == HomeLayoutMode.grid) {
      return HomeShortcutGridView(
        entries: gridEntries,
        columnCount: gridColumnCount,
      );
    }
    return listChild;
  }
}
