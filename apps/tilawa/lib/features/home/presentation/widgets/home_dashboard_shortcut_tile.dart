import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_shortcut_entry.dart';

/// Compact shortcut card for the Home dashboard grid.
class HomeDashboardShortcutTile extends StatelessWidget {
  const HomeDashboardShortcutTile({
    super.key,
    required this.entry,
  });

  final HomeShortcutEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Semantics(
        button: true,
        label: entry.semanticLabel ?? entry.title,
        child: HomeDashboardCard(
          surface: TilawaCardSurface.raised,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          onTap: entry.onTap,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Row(
              spacing: tokens.spaceMedium,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TilawaIconBox(
                  icon: entry.icon,
                  size: tokens.iconSizeMedium,
                  variant: TilawaIconBoxVariant.tinted,
                  semanticTint: TilawaSemanticTint.ink,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entry.subtitle ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
