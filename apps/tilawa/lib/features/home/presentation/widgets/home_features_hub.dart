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
          final colorScheme = Theme.of(context).colorScheme;
          final HomeExploreFeatureTileStyle style = colorScheme
              .homeExploreFeatureTileStyle(item.feature);

          return TilawaFeatureCategoryTile(
            icon: item.icon,
            iconWidget: _HomeFeatureCatalog.iconWidget(
              context,
              feature: item.feature,
              iconColor: style.iconForeground,
            ),
            label: item.label,
            onTap: item.onTap,
            backgroundColor: colorScheme.homeExploreTileBackground,
            semanticTint: style.semanticTint,
            iconBoxVariant: TilawaIconBoxVariant.plain,
            iconColor: style.iconForeground,
            tileBorderOpacity: 0.22,
          );
        },
      ),
    );
  }
}

@immutable
class _HomeFeatureItem {
  const _HomeFeatureItem({
    required this.feature,
    this.icon,
    required this.label,
    required this.onTap,
  }) : assert(
         icon != null ||
             feature == HomeExploreFeature.athkar ||
             feature == HomeExploreFeature.quran,
       );

  final HomeExploreFeature feature;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
}

abstract final class _HomeFeatureCatalog {
  /// Row 1: Reciters → Athkar → Prayer → Qibla.
  /// Row 2: Tasbeeh → Bookmarks → Quran → Support (Quran/Reciters separated).
  static List<_HomeFeatureItem> primaryFeatures(
    BuildContext context, {
    required VoidCallback onOpenPrayer,
  }) {
    final l10n = context.l10n;
    return [
      _HomeFeatureItem(
        feature: HomeExploreFeature.reciters,
        icon: TilawaIcons.reciters,
        label: l10n.homeQuickReciters,
        onTap: () => context.read<MainScreenCubit>().selectTab(1),
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.athkar,
        label: l10n.homeQuickAthkar,
        onTap: () => const AthkarCategoriesRoute().push(context),
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.prayer,
        icon: TilawaIcons.prayerDhuhr,
        label: l10n.homeQuickPrayer,
        onTap: onOpenPrayer,
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.qibla,
        icon: TilawaIcons.qibla,
        label: l10n.homeQuickQibla,
        onTap: () => const QiblaRoute().push(context),
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.tasbeeh,
        icon: Icons.brightness_7_outlined,
        label: l10n.homeQuickTasbeeh,
        onTap: () => const TasbeehRoute().push(context),
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.bookmarks,
        icon: TilawaIcons.bookmark,
        label: l10n.bookmarks,
        onTap: () => const BookmarksRoute().push(context),
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.quran,
        label: l10n.homeQuickQuran,
        onTap: () => const QuranIndexRoute().push(context),
      ),
      _HomeFeatureItem(
        feature: HomeExploreFeature.support,
        icon: TilawaIcons.support,
        label: l10n.supportTilawa,
        onTap: () => const SupportRoute().push(context),
      ),
    ];
  }

  static Widget? iconWidget(
    BuildContext context, {
    required HomeExploreFeature feature,
    required Color iconColor,
  }) {
    final double size = context.tokens.iconSizeMedium;
    return switch (feature) {
      HomeExploreFeature.athkar => TilawaIcons.athkarMisbaha.colored(
        size: size,
      ),
      HomeExploreFeature.quran => TilawaIcons.quran.svg(
        size: size,
        color: iconColor,
      ),
      _ => null,
    };
  }
}

double _homeCategoryGridTileHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final double iconExtent = tokens.iconSizeMedium + tokens.spaceSmall * 2;
  final double labelHeight = (textTheme.labelMedium?.fontSize ?? 12) * 1.2 * 2;
  return iconExtent + tokens.spaceSmall + labelHeight + tokens.spaceSmall * 2;
}
