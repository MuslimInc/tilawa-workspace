import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_shortcut_grid.dart';
import 'home_shell_tab_navigation.dart';
import 'open_home_quran_sessions.dart';

/// High-frequency entry points directly under the next-prayer hero.
///
/// Row 1: Reciters · Quran Reader.
/// Row 2: Athkar · Learn Quran with Tutor (when sessions are enabled).
/// Row 3: Qibla · Tasbeeh.
class HomeQuickActionsSection extends StatelessWidget {
  const HomeQuickActionsSection({super.key});

  static const int _columnCount = 2;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final items = _QuickActionsCatalog.items(context);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return HomeDashboardShortcutGrid(
      columnCount: _columnCount,
      tileHeight: _quickActionTileHeight(context),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final _QuickActionItem item = items[index];
        final style = colorScheme.homeExploreFeatureTileStyle(item.feature);
        final TextStyle labelStyle = textTheme.labelLarge!.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.15,
        );

        return TilawaFeatureCategoryTile(
          icon: item.icon,
          iconWidget: _QuickActionsCatalog.iconWidget(
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
          tileBorderOpacity: tokens.opacitySubtle * 2,
        );
      },
    );
  }
}

@immutable
class _QuickActionItem {
  const _QuickActionItem({
    required this.feature,
    this.icon,
    required this.label,
    required this.onTap,
  }) : assert(
         icon != null ||
             feature == HomeExploreFeature.tasbeeh ||
             feature == HomeExploreFeature.quran,
       );

  final HomeExploreFeature feature;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
}

abstract final class _QuickActionsCatalog {
  static List<_QuickActionItem> items(BuildContext context) {
    final l10n = context.l10n;
    final items = <_QuickActionItem>[
      _QuickActionItem(
        feature: HomeExploreFeature.reciters,
        icon: TilawaIcons.reciters,
        label: l10n.homeQuickReciters,
        onTap: () => openHomeRecitersTab(context),
      ),
      _QuickActionItem(
        feature: HomeExploreFeature.quran,
        label: l10n.homeQuickQuranReader,
        onTap: () => const QuranIndexRoute().push(context),
      ),
      _QuickActionItem(
        feature: HomeExploreFeature.athkar,
        icon: Icons.brightness_7_outlined,
        label: l10n.homeQuickAthkar,
        onTap: () => const AthkarCategoriesRoute().push(context),
      ),
    ];

    if (quranSessionsFeatureConfig().quranSessionsEnabled) {
      items.add(
        _QuickActionItem(
          feature: HomeExploreFeature.sessions,
          icon: FluentIcons.person_voice_24_regular,
          label: l10n.homeLearnQuranWithTutor,
          onTap: () => openHomeQuranSessions(context),
        ),
      );
    }

    items.addAll([
      _QuickActionItem(
        feature: HomeExploreFeature.qibla,
        icon: TilawaIcons.qibla,
        label: l10n.homeQuickQibla,
        onTap: () => const QiblaRoute().push(context),
      ),
      _QuickActionItem(
        feature: HomeExploreFeature.tasbeeh,
        label: l10n.homeQuickTasbeeh,
        onTap: () => const TasbeehRoute().push(context),
      ),
    ]);

    return items;
  }

  static Widget? iconWidget(
    BuildContext context, {
    required HomeExploreFeature feature,
    required Color iconColor,
    required double size,
  }) => switch (feature) {
    HomeExploreFeature.tasbeeh => TilawaIcons.athkarMisbaha.colored(size: size),
    HomeExploreFeature.quran => TilawaIcons.quran.svg(
      size: size,
      color: iconColor,
    ),
    _ => null,
  };
}

double _quickActionTileHeight(BuildContext context) {
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
