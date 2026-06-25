import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_dashboard_section.dart';
import 'home_grouped_list_row.dart';

/// Flat grouped list of secondary non-nav destinations — More zone.
///
/// Holds the less-frequent library/account destinations (History, Favorites,
/// Downloads, Smart Khatma, Support). Supporting shortcuts live in
/// [HomeDiscoverShortcuts] above this list. One flat card with hairline
/// dividers — calm density, one surface.
class HomeMoreActionsGroup extends StatelessWidget {
  const HomeMoreActionsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final items = _MoreActionsCatalog.items(context);

    if (items.isEmpty) return const SizedBox.shrink();

    return HomeDashboardSection(
      title: l10n.moreOptions,
      contentSpacing: tokens.spaceMedium,
      child: HomeDashboardCard(
        surface: TilawaCardSurface.flat,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                TilawaDivider(
                  height: tokens.borderWidthThin,
                  color: colorScheme.outlineVariant,
                ),
              _MoreActionsRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

@immutable
class _MoreActionsItem {
  const _MoreActionsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

abstract final class _MoreActionsCatalog {
  /// Secondary non-nav destinations — weekly/setup frequency.
  static List<_MoreActionsItem> items(BuildContext context) {
    final l10n = context.l10n;
    return <_MoreActionsItem>[
      _MoreActionsItem(
        icon: TilawaIcons.history,
        title: l10n.listeningHistory,
        subtitle: l10n.homeHistoryCarouselSubtitle,
        onTap: () => const HistoryRoute().push(context),
      ),
      _MoreActionsItem(
        icon: TilawaIcons.favorite,
        title: l10n.favorites,
        subtitle: l10n.homeFavoritesCarouselSubtitle,
        onTap: () => const FavoritesRoute().push(context),
      ),
      _MoreActionsItem(
        icon: TilawaIcons.download,
        title: l10n.downloads,
        subtitle: l10n.homeDownloadsCarouselSubtitle,
        onTap: () => const DownloadsRoute().push(context),
      ),
      if (isSmartKhatmaEnabled())
        _MoreActionsItem(
          icon: Icons.auto_stories_outlined,
          title: l10n.khatmaHubTitle,
          subtitle: l10n.homeKhatmaCarouselSubtitle,
          onTap: () => const SmartKhatmaHubRoute().push(context),
        ),
      _MoreActionsItem(
        icon: TilawaIcons.support,
        title: l10n.supportTilawa,
        subtitle: l10n.homeSupportCarouselSubtitle,
        onTap: () => const SupportRoute().push(context),
      ),
    ];
  }
}

class _MoreActionsRow extends StatelessWidget {
  const _MoreActionsRow({required this.item});

  final _MoreActionsItem item;

  @override
  Widget build(BuildContext context) {
    return HomeGroupedListRow(
      icon: item.icon,
      title: item.title,
      subtitle: item.subtitle,
      onTap: item.onTap,
      semanticLabel: item.title,
    );
  }
}
