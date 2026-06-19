import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_shortcut_entry.dart';

/// Compact shortcut card for the Home dashboard grid.
class HomeDashboardShortcutTile extends StatelessWidget {
  const HomeDashboardShortcutTile({
    super.key,
    required this.entry,
    this.travelStyle = false,
    this.travelTintIndex = 0,
  });

  final HomeShortcutEntry entry;
  final bool travelStyle;
  final int travelTintIndex;

  @override
  Widget build(BuildContext context) {
    if (travelStyle) {
      return _TravelShortcutTile(
        entry: entry,
        tintIndex: travelTintIndex,
      );
    }
    return _HorizontalShortcutTile(entry: entry);
  }
}

class _HorizontalShortcutTile extends StatelessWidget {
  const _HorizontalShortcutTile({required this.entry});

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

/// Travel-app destination tile: visual header band + title block.
class _TravelShortcutTile extends StatelessWidget {
  const _TravelShortcutTile({
    required this.entry,
    required this.tintIndex,
  });

  final HomeShortcutEntry entry;
  final int tintIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final Color headerTint = cardTokens.destinationHeaderTint(tintIndex);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Semantics(
        button: true,
        label: entry.semanticLabel ?? entry.title,
        child: HomeDashboardCard(
          surface: TilawaCardSurface.raised,
          padding: EdgeInsets.zero,
          borderRadius: radius,
          onTap: entry.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: headerTint,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      entry.icon,
                      size: tokens.iconSizeLarge,
                      color: cardTokens.travelDestinationIconColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceMedium,
                    vertical: tokens.spaceSmall,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      spacing: tokens.spaceExtraSmall,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (entry.subtitle case final String subtitle)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
