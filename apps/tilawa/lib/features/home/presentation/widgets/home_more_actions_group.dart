import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_dashboard_section.dart';
import 'home_grouped_list_row.dart';

/// Grouped list of secondary non-nav destinations — More zone.
///
/// Holds the less-frequent library/account destinations (History, Favorites,
/// Downloads, Support). One raised card with hairline dividers.
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
      subtitle: l10n.homeMoreOptionsSubtitle,
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
    required this.iconTint,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final TilawaSemanticTint iconTint;
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
        iconTint: TilawaSemanticTint.scholar,
        title: l10n.listeningHistory,
        subtitle: l10n.homeHistoryCarouselSubtitle,
        onTap: () => unawaited(const HistoryRoute().push<void>(context)),
      ),
      _MoreActionsItem(
        icon: TilawaIcons.favorite,
        iconTint: TilawaSemanticTint.caution,
        title: l10n.favorites,
        subtitle: l10n.homeFavoritesCarouselSubtitle,
        onTap: () => unawaited(const FavoritesRoute().push<void>(context)),
      ),
      _MoreActionsItem(
        icon: TilawaIcons.download,
        iconTint: TilawaSemanticTint.parchment,
        title: l10n.downloads,
        subtitle: l10n.homeDownloadsCarouselSubtitle,
        onTap: () => unawaited(const DownloadsRoute().push<void>(context)),
      ),
      _MoreActionsItem(
        icon: TilawaIcons.support,
        iconTint: TilawaSemanticTint.success,
        title: l10n.supportTilawa,
        subtitle: l10n.homeSupportCarouselSubtitle,
        onTap: () => unawaited(const SupportRoute().push<void>(context)),
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
      iconTint: item.iconTint,
      title: item.title,
      subtitle: item.subtitle,
      onTap: item.onTap,
      semanticLabel: item.title,
    );
  }
}
