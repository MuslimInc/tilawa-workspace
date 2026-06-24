import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma_feature_flags.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_daily_ayah_sheet.dart';
import 'home_dashboard_section.dart';
import 'home_dashboard_shortcut_grid.dart';
import 'home_travel_destination_card.dart';
import 'open_home_quran_sessions.dart';

/// Horizontal promo row — daily ayah, sessions, khatma, library shortcuts.
class HomeDiscoverCarousel extends StatelessWidget {
  const HomeDiscoverCarousel({super.key});

  static const double _carouselTileWidth = 168;

  @override
  Widget build(BuildContext context) {
    final items = _HomeDiscoverCarouselCatalog.items(context);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final double tileHeight = homeTravelGridTileHeight(context);

    return HomeDashboardSection(
      title: context.l10n.homeFeaturedTitle,
      contentSpacing: tokens.spaceMedium,
      child: SizedBox(
        height: tileHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSmall),
          itemBuilder: (context, index) {
            final _HomeDiscoverCarouselItem item = items[index];
            return SizedBox(
              width: _carouselTileWidth,
              child: HomeTravelDestinationCard(
                tintIndex: item.tintIndex,
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                onTap: item.onTap,
                semanticLabel: item.title,
              ),
            );
          },
        ),
      ),
    );
  }
}

@immutable
class _HomeDiscoverCarouselItem {
  const _HomeDiscoverCarouselItem({
    required this.tintIndex,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final int tintIndex;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

abstract final class _HomeDiscoverCarouselCatalog {
  static List<_HomeDiscoverCarouselItem> items(BuildContext context) {
    final l10n = context.l10n;
    final int ayahIndex = homeDailyInspirationCatalogIndex(DateTime.now());
    final _DailyAyahPromo ayah = _resolveAyahPromo(l10n, ayahIndex);

    return <_HomeDiscoverCarouselItem>[
      _HomeDiscoverCarouselItem(
        tintIndex: 0,
        icon: Icons.auto_awesome_outlined,
        title: l10n.homeDailyAyahLabel,
        subtitle: ayah.preview,
        onTap: () => showHomeDailyAyahSheet(
          context,
          catalogIndex: ayahIndex,
        ),
      ),
      if (quranSessionsFeatureConfig().quranSessionsEnabled)
        _HomeDiscoverCarouselItem(
          tintIndex: 1,
          icon: FluentIcons.person_voice_24_regular,
          title: l10n.homeSessionsTitle,
          subtitle: l10n.homeSessionsSubtitle,
          onTap: () => openHomeQuranSessions(context),
        ),
      if (isSmartKhatmaEnabled())
        _HomeDiscoverCarouselItem(
          tintIndex: 2,
          icon: Icons.auto_stories_outlined,
          title: l10n.khatmaHubTitle,
          subtitle: l10n.homeKhatmaCarouselSubtitle,
          onTap: () => const SmartKhatmaHubRoute().push(context),
        ),
      _HomeDiscoverCarouselItem(
        tintIndex: 3,
        icon: TilawaIcons.support,
        title: l10n.supportTilawa,
        subtitle: l10n.homeSupportCarouselSubtitle,
        onTap: () => const SupportRoute().push(context),
      ),
      _HomeDiscoverCarouselItem(
        tintIndex: 4,
        icon: TilawaIcons.history,
        title: l10n.listeningHistory,
        subtitle: l10n.homeHistoryCarouselSubtitle,
        onTap: () => const HistoryRoute().push(context),
      ),
      _HomeDiscoverCarouselItem(
        tintIndex: 5,
        icon: TilawaIcons.favorite,
        title: l10n.favorites,
        subtitle: l10n.homeFavoritesCarouselSubtitle,
        onTap: () => const FavoritesRoute().push(context),
      ),
      _HomeDiscoverCarouselItem(
        tintIndex: 6,
        icon: TilawaIcons.download,
        title: l10n.downloads,
        subtitle: l10n.homeDownloadsCarouselSubtitle,
        onTap: () => const DownloadsRoute().push(context),
      ),
    ];
  }
}

class _DailyAyahPromo {
  const _DailyAyahPromo({required this.preview});

  final String preview;
}

_DailyAyahPromo _resolveAyahPromo(AppLocalizations l10n, int index) {
  final String body = switch (index) {
    1 => l10n.homeDailyAyahBody1,
    2 => l10n.homeDailyAyahBody2,
    _ => l10n.homeDailyAyahBody,
  };
  return _DailyAyahPromo(preview: body);
}
