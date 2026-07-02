import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quran_resume_card.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_catalog_grouped_list.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_catalog_tab.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_catalog_tiles.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_tile.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Full-screen Quran hub: Last Read card, catalog pills, and surah/juz/page lists.
class QuranIndexScreen extends StatefulWidget {
  const QuranIndexScreen({super.key});

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  QuranCatalogTab _selectedTab = QuranCatalogTab.surah;

  void _openSurah(int surahNumber, {int? ayahNumber}) {
    QuranReaderRoute(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    ).push(context);
  }

  void _openJuz(int juzNumber) {
    final Juz? juz = getJuz(juzNumber);
    if (juz == null) {
      return;
    }
    final ({int surah, int verse}) start = juz.start;
    _openSurah(start.surah, ayahNumber: start.verse);
  }

  void _openPage(int pageNumber) {
    final List<PageSurahEntry> pageData = getPageData(pageNumber);
    if (pageData.isEmpty) {
      return;
    }
    final PageSurahEntry first = pageData.first;
    _openSurah(first.surah, ayahNumber: first.start);
  }

  Widget _buildCatalogSegments(BuildContext context) {
    return TilawaSegmentedControl<QuranCatalogTab>(
      selectedValue: _selectedTab,
      onValueChanged: (value) => setState(() => _selectedTab = value),
      segments: [
        TilawaSegment(
          value: QuranCatalogTab.surah,
          label: context.l10n.surahPrefix,
        ),
        TilawaSegment(
          value: QuranCatalogTab.juz,
          label: context.l10n.juz,
        ),
        TilawaSegment(
          value: QuranCatalogTab.page,
          label: context.l10n.page,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaSettingsGroupTokens groupTokens =
        theme.componentTokens.settingsGroup;
    final double scrollBottomPadding = listScrollBottomPadding(context);
    final double segmentBarHeight = TilawaSegmentedControl.layoutHeight(
      context,
    );
    return Scaffold(
      appBar: TilawaCatalogAppBar(
        preferredHeight: TilawaCatalogAppBar.resolvePreferredHeight(
          context,
          title: context.l10n.quranHubTitle,
          automaticallyImplyLeading: false,
          bottomContentHeight: segmentBarHeight + tokens.spaceSmall,
        ),
        title: context.l10n.quranHubTitle,
        automaticallyImplyLeading: false,
        bottomContent: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            groupTokens.groupHorizontalPadding,
            0,
            groupTokens.groupHorizontalPadding,
            tokens.spaceSmall,
          ),
          child: _buildCatalogSegments(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              groupTokens.groupHorizontalPadding,
              tokens.spaceSmall,
              groupTokens.groupHorizontalPadding,
              tokens.spaceSmall,
            ),
            sliver: const SliverToBoxAdapter(
              child: HomeQuranResumeCard(featured: true, hubLayout: true),
            ),
          ),
          _QuranCatalogSliver(
            tab: _selectedTab,
            onOpenSurah: _openSurah,
            onOpenJuz: _openJuz,
            onOpenPage: _openPage,
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: scrollBottomPadding),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}

class _QuranCatalogSliver extends StatelessWidget {
  const _QuranCatalogSliver({
    required this.tab,
    required this.onOpenSurah,
    required this.onOpenJuz,
    required this.onOpenPage,
  });

  final QuranCatalogTab tab;
  final void Function(int surahNumber) onOpenSurah;
  final void Function(int juzNumber) onOpenJuz;
  final void Function(int pageNumber) onOpenPage;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      QuranCatalogTab.surah => QuranCatalogGroupedSliver(
        itemCount: 114,
        itemBuilder: (context, index) {
          final int surahNumber = index + 1;
          return SurahIndexTile(
            surahNumber: surahNumber,
            grouped: true,
            onTap: () => onOpenSurah(surahNumber),
          );
        },
      ),
      QuranCatalogTab.juz => QuranCatalogGroupedSliver(
        itemCount: 30,
        itemBuilder: (context, index) {
          final int juzNumber = index + 1;
          return JuzIndexTile(
            juzNumber: juzNumber,
            grouped: true,
            onTap: () => onOpenJuz(juzNumber),
          );
        },
      ),
      QuranCatalogTab.page => QuranCatalogGroupedSliver(
        itemCount: 604,
        itemBuilder: (context, index) {
          final int pageNumber = index + 1;
          return PageIndexTile(
            pageNumber: pageNumber,
            grouped: true,
            onTap: () => onOpenPage(pageNumber),
          );
        },
      ),
    };
  }
}
