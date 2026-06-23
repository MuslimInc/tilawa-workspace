import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_section.dart';
import 'home_dashboard_shortcut_grid.dart';

/// Talabat-style feature category grid for everyday Tilawa tools.
class HomeFeaturesHub extends StatelessWidget {
  const HomeFeaturesHub({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  static const int _categoryColumnCount = 4;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final features = _HomeFeatureCatalog.primaryFeatures(
      context,
      onOpenPrayer: onOpenPrayer,
    );

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return HomeDashboardSection(
      title: context.l10n.homeExploreTitle,
      subtitle: context.l10n.homeExploreSubtitle,
      contentSpacing: tokens.spaceMedium,
      child: HomeDashboardShortcutGrid(
        columnCount: _categoryColumnCount,
        tileHeight: _homeCategoryGridTileHeight(context),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final _HomeFeatureItem item = features[index];
          return TilawaFeatureCategoryTile(
            icon: item.icon,
            iconWidget: item.iconWidget,
            label: item.label,
            onTap: item.onTap,
            semanticTint: item.tint,
            tintIndex: index,
          );
        },
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
  static List<_HomeFeatureItem> primaryFeatures(
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
      _HomeFeatureItem(
        icon: TilawaIcons.bookmark,
        label: l10n.bookmarks,
        onTap: () => const BookmarksRoute().push(context),
        tint: TilawaSemanticTint.ink,
      ),
      _HomeFeatureItem(
        icon: FluentIcons.book_open_24_regular,
        label: l10n.homeQuickQuran,
        onTap: () => const QuranIndexRoute().push(context),
        tint: TilawaSemanticTint.gilding,
      ),
      _HomeFeatureItem(
        icon: FluentIcons.headphones_sound_wave_24_regular,
        label: l10n.homeQuickReciters,
        onTap: () => context.read<MainScreenCubit>().selectTab(1),
        tint: TilawaSemanticTint.scholar,
      ),
      _HomeFeatureItem(
        icon: TilawaIcons.support,
        label: l10n.supportTilawa,
        onTap: () => const SupportRoute().push(context),
        tint: TilawaSemanticTint.success,
      ),
    ];
  }
}

double _homeCategoryGridTileHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final double iconExtent = tokens.iconSizeMedium + tokens.spaceSmall * 2;
  final double labelHeight = (textTheme.labelMedium?.fontSize ?? 12) * 1.2 * 2;
  return iconExtent + tokens.spaceSmall + labelHeight + tokens.spaceSmall * 2;
}
