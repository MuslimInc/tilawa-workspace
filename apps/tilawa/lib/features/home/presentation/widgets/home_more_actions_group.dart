import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_grouped_list_row.dart';

/// Secondary Home destinations grouped in one raised card.
class HomeMoreAction {
  const HomeMoreAction({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Optional widget replacing the default chevron (e.g. a badge).
  final Widget? trailing;
}

/// Reciters and Qibla — destinations outside bottom navigation.
class HomeMoreActionsGroup extends StatelessWidget {
  const HomeMoreActionsGroup({super.key, required this.actions});

  final List<HomeMoreAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final Color dividerColor = colorScheme.outlineVariant;

    return HomeDashboardCard(
      surface: TilawaCardSurface.flat,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0)
              TilawaDivider(
                height: tokens.borderWidthThin,
                color: dividerColor,
              ),
            HomeGroupedListRow(
              icon: actions[i].icon,
              title: actions[i].label,
              subtitle: actions[i].subtitle,
              onTap: actions[i].onTap,
              trailingWidget: actions[i].trailing,
            ),
          ],
        ],
      ),
    );
  }
}
