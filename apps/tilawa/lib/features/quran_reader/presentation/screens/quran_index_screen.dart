import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quran_resume_card.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_catalog_tab.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_catalog_tiles.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_tile.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final double listBottomPadding =
        QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge;

    return Scaffold(
      appBar: TilawaCatalogAppBar(
        preferredHeight: TilawaAppBarConfig.catalogTitleOnlyHeight(context),
        centerTitle: true,
        titleWidget: Text(
          context.l10n.quranHubTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceMedium,
            ),
            child: const HomeQuranResumeCard(),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              tokens.spaceLarge,
              0,
              tokens.spaceLarge,
              tokens.spaceSmall,
            ),
            child: Text(
              context.l10n.quranCatalogSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              tokens.spaceLarge,
              tokens.spaceSmall,
              tokens.spaceLarge,
              tokens.spaceMedium,
            ),
            child: TilawaSegmentedControl<QuranCatalogTab>(
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
            ),
          ),
          Expanded(
            child: _QuranCatalogList(
              tab: _selectedTab,
              bottomPadding: listBottomPadding,
              onOpenSurah: _openSurah,
              onOpenJuz: _openJuz,
              onOpenPage: _openPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranCatalogList extends StatelessWidget {
  const _QuranCatalogList({
    required this.tab,
    required this.bottomPadding,
    required this.onOpenSurah,
    required this.onOpenJuz,
    required this.onOpenPage,
  });

  final QuranCatalogTab tab;
  final double bottomPadding;
  final void Function(int surahNumber) onOpenSurah;
  final void Function(int juzNumber) onOpenJuz;
  final void Function(int pageNumber) onOpenPage;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    return switch (tab) {
      QuranCatalogTab.surah => ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceLarge,
          0,
          tokens.spaceLarge,
          bottomPadding,
        ),
        itemCount: 114,
        separatorBuilder: (_, _) => SizedBox(height: tokens.spaceSmall),
        itemBuilder: (context, index) {
          final int surahNumber = index + 1;
          return SurahIndexTile(
            surahNumber: surahNumber,
            onTap: () => onOpenSurah(surahNumber),
          );
        },
      ),
      QuranCatalogTab.juz => ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceLarge,
          0,
          tokens.spaceLarge,
          bottomPadding,
        ),
        itemCount: 30,
        separatorBuilder: (_, _) => SizedBox(height: tokens.spaceSmall),
        itemBuilder: (context, index) {
          final int juzNumber = index + 1;
          return JuzIndexTile(
            juzNumber: juzNumber,
            onTap: () => onOpenJuz(juzNumber),
          );
        },
      ),
      QuranCatalogTab.page => ListView.builder(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceLarge,
          0,
          tokens.spaceLarge,
          bottomPadding,
        ),
        itemCount: 604,
        itemBuilder: (context, index) {
          final int pageNumber = index + 1;
          return Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSmall),
            child: PageIndexTile(
              pageNumber: pageNumber,
              onTap: () => onOpenPage(pageNumber),
            ),
          );
        },
      ),
    };
  }
}
