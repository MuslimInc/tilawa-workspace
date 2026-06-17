import 'package:flutter/material.dart';

import 'home_dashboard_shortcut_grid.dart';
import 'home_dashboard_shortcut_tile.dart';
import 'home_shortcut_entry.dart';

/// Grid of [HomeShortcutEntry] tiles with stable LTR/RTL row layout.
class HomeShortcutGridView extends StatelessWidget {
  const HomeShortcutGridView({
    super.key,
    required this.entries,
    this.columnCount,
  });

  final List<HomeShortcutEntry> entries;
  final int? columnCount;

  @override
  Widget build(BuildContext context) {
    return HomeDashboardShortcutGrid(
      columnCount: columnCount,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return HomeDashboardShortcutTile(entry: entries[index]);
      },
    );
  }
}
