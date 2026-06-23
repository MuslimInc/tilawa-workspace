import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_dashboard_section.dart';
import 'home_dashboard_shortcut_grid.dart';
import 'open_home_quran_sessions.dart';

/// Home feature hub — quick-action row plus a discover grid for tools that
/// are not bottom-nav tabs.
class HomeFeaturesHub extends StatelessWidget {
  const HomeFeaturesHub({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final quickActions = _HomeFeatureCatalog.quickActions(
      context,
      onOpenPrayer: onOpenPrayer,
    );
    final gridFeatures = _HomeFeatureCatalog.gridFeatures(context);

    if (quickActions.isEmpty && gridFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quickActions.isNotEmpty) ...[
          _HomeQuickActionsRow(items: quickActions),
          SizedBox(height: tokens.spaceLarge),
        ],
        if (gridFeatures.isNotEmpty)
          HomeDashboardSection(
            title: context.l10n.homeExploreTitle,
            subtitle: context.l10n.homeExploreSubtitle,
            contentSpacing: tokens.spaceMedium,
            child: HomeDashboardShortcutGrid(
              columnCount: 3,
              tileHeight: _homeFeatureGridTileHeight(context),
              itemCount: gridFeatures.length,
              itemBuilder: (context, index) {
                final _HomeFeatureItem item = gridFeatures[index];
                return _HomeFeatureGridTile(item: item);
              },
            ),
          ),
      ],
    );
  }
}

class _HomeQuickActionsRow extends StatelessWidget {
  const _HomeQuickActionsRow({required this.items});

  final List<_HomeFeatureItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: tokens.spaceSmall,
          horizontal: tokens.spaceExtraSmall,
        ),
        child: SizedBox(
          height: _homeQuickActionRowHeight(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = _homeQuickActionsContentWidth(
                context,
                items.length,
              );
              final needsScroll = contentWidth > constraints.maxWidth;

              if (needsScroll) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(width: tokens.spaceSmall),
                  itemBuilder: (context, index) {
                    return _HomeQuickActionTile(item: items[index]);
                  },
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) SizedBox(width: tokens.spaceSmall),
                    _HomeQuickActionTile(item: items[index]),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeQuickActionTile extends StatelessWidget {
  const _HomeQuickActionTile({required this.item});

  final _HomeFeatureItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double tileWidth = _homeQuickActionTileWidth(context);

    return Semantics(
      button: true,
      label: item.label,
      child: SizedBox(
        width: tileWidth,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceExtraSmall,
                vertical: tokens.spaceExtraSmall,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TilawaIconBox(
                    icon: item.icon ?? Icons.circle_outlined,
                    size: tokens.iconSizeMedium,
                    padding: tokens.spaceSmall,
                    variant: TilawaIconBoxVariant.tinted,
                    semanticTint: item.tint,
                    child: item.iconWidget,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFeatureGridTile extends StatelessWidget {
  const _HomeFeatureGridTile({required this.item});

  final _HomeFeatureItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: item.label,
      child: HomeDashboardCard(
        surface: TilawaCardSurface.raised,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceMedium,
        ),
        onTap: item.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TilawaIconBox(
              icon: item.icon ?? Icons.circle_outlined,
              size: tokens.iconSizeMedium,
              padding: tokens.spaceSmall,
              variant: TilawaIconBoxVariant.tinted,
              semanticTint: item.tint,
              child: item.iconWidget,
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _HomeFeatureItem {
  const _HomeFeatureItem({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    required this.tint,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final TilawaSemanticTint tint;
}

abstract final class _HomeFeatureCatalog {
  static List<_HomeFeatureItem> quickActions(
    BuildContext context, {
    required VoidCallback onOpenPrayer,
  }) {
    final l10n = context.l10n;
    return [
      _HomeFeatureItem(
        iconWidget: TilawaIcons.athkarMisbaha.colored(
          size: context.tokens.iconSizeMedium,
        ),
        label: l10n.homeQuickAthkar,
        onTap: () => const AthkarCategoriesRoute().push(context),
        tint: TilawaSemanticTint.ink,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.qibla,
        label: l10n.homeQuickQibla,
        onTap: () => const QiblaRoute().push(context),
        tint: TilawaSemanticTint.scholar,
      ),
      _HomeFeatureItem(
        icon: Icons.brightness_7_outlined,
        label: l10n.homeQuickTasbeeh,
        onTap: () => const TasbeehRoute().push(context),
        tint: TilawaSemanticTint.gilding,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.prayerDhuhr,
        label: l10n.homeQuickPrayer,
        onTap: onOpenPrayer,
        tint: TilawaSemanticTint.parchment,
      ),
    ];
  }

  static List<_HomeFeatureItem> gridFeatures(BuildContext context) {
    final l10n = context.l10n;
    final items = <_HomeFeatureItem>[
      _HomeFeatureItem(
        icon: TilawaIcons.bookmark,
        label: l10n.bookmarks,
        onTap: () => const BookmarksRoute().push(context),
        tint: TilawaSemanticTint.ink,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.history,
        label: l10n.listeningHistory,
        onTap: () => const HistoryRoute().push(context),
        tint: TilawaSemanticTint.scholar,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.favorite,
        label: l10n.favorites,
        onTap: () => const FavoritesRoute().push(context),
        tint: TilawaSemanticTint.gilding,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.download,
        label: l10n.downloads,
        onTap: () => const DownloadsRoute().push(context),
        tint: TilawaSemanticTint.neutral,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.support,
        label: l10n.supportTilawa,
        onTap: () => const SupportRoute().push(context),
        tint: TilawaSemanticTint.success,
      ),
    ];

    if (quranSessionsFeatureConfig().quranSessionsEnabled) {
      items.insert(
        4,
        _HomeFeatureItem(
          icon: FluentIcons.person_voice_24_regular,
          label: l10n.homeSessionsTitle,
          onTap: () => openHomeQuranSessions(context),
          tint: TilawaSemanticTint.caution,
        ),
      );
    }

    if (isSmartKhatmaEnabled()) {
      items.add(
        _HomeFeatureItem(
          icon: Icons.auto_stories_outlined,
          label: l10n.khatmaHubTitle,
          onTap: () => const SmartKhatmaHubRoute().push(context),
          tint: TilawaSemanticTint.parchment,
        ),
      );
    }

    return items;
  }
}

double _homeQuickActionTileWidth(BuildContext context) {
  return Theme.of(context).tokens.minInteractiveDimension * 1.35;
}

double _homeQuickActionsContentWidth(BuildContext context, int itemCount) {
  if (itemCount == 0) {
    return 0;
  }
  final tokens = Theme.of(context).tokens;
  final tileWidth = _homeQuickActionTileWidth(context);
  return itemCount * tileWidth + (itemCount - 1) * tokens.spaceSmall;
}

double _homeQuickActionRowHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final double iconExtent = tokens.iconSizeMedium + tokens.spaceSmall * 2;
  final double labelHeight = (textTheme.labelMedium?.fontSize ?? 12) * 1.2 * 2;
  return iconExtent +
      tokens.spaceSmall +
      labelHeight +
      tokens.spaceExtraSmall * 2;
}

double _homeFeatureGridTileHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final double iconExtent = tokens.iconSizeMedium + tokens.spaceSmall * 2;
  final double labelHeight = (textTheme.labelMedium?.fontSize ?? 12) * 1.2 * 2;
  return iconExtent + tokens.spaceSmall + labelHeight + tokens.spaceMedium * 2;
}
