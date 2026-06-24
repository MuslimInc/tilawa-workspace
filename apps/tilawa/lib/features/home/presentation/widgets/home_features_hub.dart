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

/// Feature category grid for everyday Tilawa tools.
class HomeFeaturesHub extends StatelessWidget {
  const HomeFeaturesHub({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  static const int _categoryColumnCountWide = 4;
  static const int _categoryColumnCountNarrow = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );
    final features = _HomeFeatureCatalog.primaryFeatures(
      context,
      onOpenPrayer: onOpenPrayer,
    );

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: cardTokens.backgroundGradient(),
        border: Border.all(
          color: cardTokens.borderColor,
          width: tokens.borderWidthThin,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: tokens.opacityShadow,
            ),
            offset: tokens.shadowOffsetSmall,
            blurRadius: tokens.spaceSmall.toDouble(),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: HomeDashboardSection(
          title: context.l10n.homeExploreTitle,
          subtitle: context.l10n.homeExploreSubtitle,
          contentSpacing: tokens.spaceSmall,
          child: HomeDashboardShortcutGrid(
            columnCount: _homeFeaturesHubColumnCount(context),
            tileHeight: _homeCategoryGridTileHeight(context),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final _HomeFeatureItem item = features[index];
              final HomeExploreFeatureTileStyle style = colorScheme
                  .homeExploreFeatureTileStyle(item.feature);
              final TextStyle hubLabelStyle = textTheme.titleSmall!.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.15,
              );

              return TilawaFeatureCategoryTile(
                icon: item.icon,
                iconWidget: _HomeFeatureCatalog.iconWidget(
                  context,
                  feature: item.feature,
                  iconColor: style.iconForeground,
                  size: tokens.iconSizeLarge,
                ),
                label: item.label,
                onTap: item.onTap,
                backgroundColor: colorScheme.homeExploreTileBackground,
                iconBoxVariant: TilawaIconBoxVariant.tinted,
                iconBoxBackgroundColor: colorScheme.surface,
                iconColor: style.iconForeground,
                iconSize: tokens.iconSizeLarge,
                iconPadding: tokens.spaceSmall,
                labelStyle: hubLabelStyle,
                contentPadding: EdgeInsets.all(tokens.spaceSmall),
              );
            },
          ),
        ),
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
  /// Row 2: Tasbeeh → Bookmarks → Quran → Support.
  /// Row 3 (narrow): Sessions — wide uses a single trailing tile on row 3.
  static List<_HomeFeatureItem> primaryFeatures(
    BuildContext context, {
    required VoidCallback onOpenPrayer,
  }) {
    final l10n = context.l10n;
    final features = <_HomeFeatureItem>[
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

    if (quranSessionsFeatureConfig().quranSessionsEnabled) {
      features.add(
        _HomeFeatureItem(
          feature: HomeExploreFeature.sessions,
          icon: FluentIcons.person_voice_24_regular,
          label: l10n.homeSessionsTitle,
          onTap: () => openHomeQuranSessions(context),
        ),
      );
    }

    return features;
  }

  static Widget? iconWidget(
    BuildContext context, {
    required HomeExploreFeature feature,
    required Color iconColor,
    required double size,
  }) {
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

int _homeFeaturesHubColumnCount(BuildContext context) {
  return context.isAtLeastMedium
      ? HomeFeaturesHub._categoryColumnCountWide
      : HomeFeaturesHub._categoryColumnCountNarrow;
}

double _homeCategoryGridTileHeight(BuildContext context) {
  final tokens = Theme.of(context).tokens;
  final textTheme = Theme.of(context).textTheme;
  final textScaler = MediaQuery.textScalerOf(context);
  const double labelLineHeightFactor = 1.15;
  final double tilePadding = tokens.spaceSmall;
  final double iconExtent = tokens.iconSizeLarge + tokens.spaceSmall * 2;
  final double labelFontSize = textTheme.titleSmall?.fontSize ?? 14;
  final double labelLineHeight =
      textScaler.scale(labelFontSize) * labelLineHeightFactor;
  final double labelBlockHeight = labelLineHeight * 2;
  return tilePadding * 2 + iconExtent + tokens.spaceSmall + labelBlockHeight;
}
