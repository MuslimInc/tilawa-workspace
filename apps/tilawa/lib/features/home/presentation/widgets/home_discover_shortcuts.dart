import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_section.dart';
import 'home_dashboard_shortcut_grid.dart';
import 'open_home_quran_sessions.dart';

/// Compact supporting shortcuts for quick access after the daily ritual content.
///
/// Reciters/Qibla/Tasbeeh/Bookmarks remain one tap from Home, but this block
/// stays visually quieter than the primary resume and daily practice surfaces.
/// Nav-duplicate routes (Prayer, Athkar, Quran, Settings) are excluded.
class HomeDiscoverShortcuts extends StatelessWidget {
  const HomeDiscoverShortcuts({super.key});

  static const int _columnCountWide = 4;
  static const int _columnCountNarrow = 2;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final items = _DiscoverCatalog.items(context);

    if (items.isEmpty) return const SizedBox.shrink();

    return HomeDashboardSection(
      title: context.l10n.homeExploreTitle,
      subtitle: context.l10n.homeExploreSubtitle,
      contentSpacing: tokens.spaceSmall,
      child: HomeDashboardShortcutGrid(
        columnCount: _columnCount(context),
        tileHeight: _discoverTileHeight(context),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final _DiscoverItem item = items[index];
          final style = colorScheme.homeExploreFeatureTileStyle(
            item.feature,
          );
          final TextStyle labelStyle = textTheme.labelLarge!.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.15,
          );
          return TilawaFeatureCategoryTile(
            icon: item.icon,
            iconWidget: _DiscoverCatalog.iconWidget(
              context,
              feature: item.feature,
              iconColor: style.iconForeground,
              size: tokens.iconSizeMedium,
            ),
            label: item.label,
            onTap: item.onTap,
            backgroundColor: colorScheme.surface,
            iconBoxVariant: TilawaIconBoxVariant.tinted,
            iconBoxBackgroundColor: colorScheme.surfaceContainerHigh,
            iconColor: style.iconForeground,
            iconSize: tokens.iconSizeMedium,
            iconPadding: tokens.spaceSmall,
            labelStyle: labelStyle,
            contentPadding: EdgeInsets.all(tokens.spaceSmall),
            tileBorderOpacity: tokens.opacitySubtle,
          );
        },
      ),
    );
  }
}

@immutable
class _DiscoverItem {
  const _DiscoverItem({
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

abstract final class _DiscoverCatalog {
  /// Several-times-daily non-nav destinations only.
  /// Row 1: Reciters → Qibla.
  /// Row 2: Tasbeeh → Bookmarks.
  /// Row 3 (narrow) / trailing (wide): Sessions when enabled.
  static List<_DiscoverItem> items(BuildContext context) {
    final l10n = context.l10n;
    final items = <_DiscoverItem>[
      _DiscoverItem(
        feature: HomeExploreFeature.reciters,
        icon: TilawaIcons.reciters,
        label: l10n.homeQuickReciters,
        onTap: () => context.read<MainScreenCubit>().selectTab(1),
      ),
      _DiscoverItem(
        feature: HomeExploreFeature.qibla,
        icon: TilawaIcons.qibla,
        label: l10n.homeQuickQibla,
        onTap: () => const QiblaRoute().push(context),
      ),
      _DiscoverItem(
        feature: HomeExploreFeature.tasbeeh,
        icon: Icons.brightness_7_outlined,
        label: l10n.homeQuickTasbeeh,
        onTap: () => const TasbeehRoute().push(context),
      ),
      _DiscoverItem(
        feature: HomeExploreFeature.bookmarks,
        icon: TilawaIcons.bookmark,
        label: l10n.bookmarks,
        onTap: () => const BookmarksRoute().push(context),
      ),
    ];

    if (quranSessionsFeatureConfig().quranSessionsEnabled) {
      items.add(
        _DiscoverItem(
          feature: HomeExploreFeature.sessions,
          icon: FluentIcons.person_voice_24_regular,
          label: l10n.homeSessionsTitle,
          onTap: () => openHomeQuranSessions(context),
        ),
      );
    }

    return items;
  }

  static Widget? iconWidget(
    BuildContext context, {
    required HomeExploreFeature feature,
    required Color iconColor,
    required double size,
  }) => switch (feature) {
    HomeExploreFeature.athkar => TilawaIcons.athkarMisbaha.colored(size: size),
    HomeExploreFeature.quran => TilawaIcons.quran.svg(
      size: size,
      color: iconColor,
    ),
    _ => null,
  };
}

int _columnCount(BuildContext context) {
  return context.isAtLeastMedium
      ? HomeDiscoverShortcuts._columnCountWide
      : HomeDiscoverShortcuts._columnCountNarrow;
}

double _discoverTileHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final textScaler = MediaQuery.textScalerOf(context);
  const double labelLineHeightFactor = 1.15;
  final double tilePadding = tokens.spaceSmall;
  final double iconExtent = tokens.iconSizeMedium + tokens.spaceSmall * 2;
  final double labelFontSize = textTheme.labelLarge?.fontSize ?? 14;
  final double labelLineHeight =
      textScaler.scale(labelFontSize) * labelLineHeightFactor;
  final double labelBlockHeight = labelLineHeight * 2;
  return tilePadding * 2 + iconExtent + tokens.spaceSmall + labelBlockHeight;
}
