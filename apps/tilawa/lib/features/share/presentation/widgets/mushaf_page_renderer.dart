import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../utils/video_page_specs.dart';

/// Renders a single mushaf page for share media generation.
///
/// Kept abstract so the composition root can swap implementations (e.g. a
/// premium branded renderer or a per-locale variant) without touching the
/// widget tree. Today one implementation ships: [QcfMushafPageRenderer].
abstract class MushafPageRenderer {
  const MushafPageRenderer();

  /// Returns the default implementation. Call this at the composition root
  /// (screen/widget builder) so widget `build` methods stay pure.
  factory MushafPageRenderer.defaultRenderer() = QcfMushafPageRenderer;

  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color textColor,
    required Color pageBackgroundColor,
  });
}

/// Renders a mushaf page using QCF/QCP fonts from the local `quran` package.
///
/// Produces a typographically faithful mushaf page that responds to viewport
/// width and supports per-verse background colors. Depends on
/// [QuranFontService] for on-demand font loading and
/// [QuranPagePreparationService] for layout.
class QcfMushafPageRenderer extends MushafPageRenderer {
  const QcfMushafPageRenderer();

  @override
  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color textColor,
    required Color pageBackgroundColor,
  }) {
    return _QcfPage(
      pageSpec: pageSpec,
      surahNumber: surahNumber,
      verseBackgroundColor: verseBackgroundColor,
      textColor: textColor,
      pageBackgroundColor: pageBackgroundColor,
    );
  }
}

class _QcfPage extends StatelessWidget {
  static const Color _frameTextColor = Color(0xFF6B5B4F);
  static const Color _frameAccentColor = Color(0xFFC5A358);
  static const Color _frameSurfaceColor = Color(0xFFFFF9F2);

  const _QcfPage({
    required this.pageSpec,
    required this.surahNumber,
    required this.verseBackgroundColor,
    required this.textColor,
    required this.pageBackgroundColor,
  });

  final VideoPageSpec pageSpec;
  final int surahNumber;
  final Color? Function(int surah, int verse) verseBackgroundColor;
  final Color textColor;
  final Color pageBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mushafService = quranQcfLocator<MushafService>();
        final PageMetadata meta = mushafService.getPageMetadata(
          pageSpec.pageNumber,
        );
        final List<String> surahNames = meta.surahNumbers
            .map(getSurahNameArabic)
            .toList(growable: false);

        return ListenableBuilder(
          listenable: quranQcfLocator<QuranFontService>(),
          builder: (context, _) {
            final fontService = quranQcfLocator<QuranFontService>();
            final bool isFontLoaded = fontService.isFontLoaded(
              pageSpec.pageNumber,
            );

            if (!isFontLoaded) {
              // Actively kick off loading so the ListenableBuilder is notified
              // when done. Safe to call repeatedly — the service deduplicates
              // in-flight requests.
              fontService.ensureSingleFontLoaded(pageSpec.pageNumber);
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _ReelTopBar(
                    pageHeight: constraints.maxHeight,
                    surahNames: surahNames,
                    juzNumber: meta.juz,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final metrics = StandardQuranLayoutStrategy()
                            .calculateMetrics(
                              context,
                              bodyConstraints,
                              pageSpec.pageNumber,
                              mushafService,
                            );
                        final preparedPage =
                            quranQcfLocator<QuranPagePreparationService>()
                                .preparePage(
                                  pageNumber: pageSpec.pageNumber,
                                  metrics: metrics,
                                  viewportWidth: bodyConstraints.maxWidth,
                                  textColor: textColor,
                                  verseBackgroundColor: verseBackgroundColor,
                                  mushafService: mushafService,
                                );
                        final fixedPreparedPage = _injectMissingSurahHeaders(
                          preparedPage,
                        );

                        return PageContent(
                          mushafService: mushafService,
                          pageSnapshotService:
                              quranQcfLocator<PageSnapshotService>(),
                          pageNumber: pageSpec.pageNumber,
                          preparedPage: fixedPreparedPage,
                          textColor: textColor,
                          pageBackgroundColor: pageBackgroundColor,
                          alignTextToTop: true,
                          // Highlights are already baked into preparedPage;
                          // keeping this null ensures PageContent uses the
                          // prepared render path that preserves inline Surah
                          // header blocks.
                          verseBackgroundColor: null,
                          uiTextDirection: TextDirection.rtl,
                          showOverlaysListenable: _kHiddenOverlaysListenable,
                        );
                      },
                    ),
                  ),
                  // _ReelBottomBar(
                  //   pageWidth: constraints.maxWidth,
                  //   pageHeight: constraints.maxHeight,
                  //   pageNumber: pageSpec.pageNumber,
                  //   hizbNumber: meta.hizb,
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreparedQuranPage _injectMissingSurahHeaders(PreparedQuranPage page) {
    final List<PreparedPageBlock> mergedBlocks = <PreparedPageBlock>[];
    final Set<int> announcedSurahs = <int>{};
    int? lastTextSurah;

    for (final PreparedPageBlock block in page.blocks) {
      if (block is PreparedHeaderBlock) {
        announcedSurahs.add(block.surahNumber);
        mergedBlocks.add(block);
        continue;
      }

      if (block is PreparedTextBlock && block.metadata.isNotEmpty) {
        final int blockSurah = block.metadata.first.surah;
        final bool containsOpeningAyah = block.metadata.any(
          (word) => word.verse == 1,
        );

        final bool shouldInsertHeader =
            containsOpeningAyah &&
            !announcedSurahs.contains(blockSurah) &&
            blockSurah != lastTextSurah;

        final bool shouldInsertBismillah =
            containsOpeningAyah &&
            _needsStandaloneBismillah(blockSurah) &&
            !_lastMeaningfulBlockIsBismillah(mergedBlocks);

        if (shouldInsertHeader) {
          _consumeTrailingSpacerSlots(
            mergedBlocks,
            slotCount: shouldInsertBismillah ? 2 : 1,
          );
          mergedBlocks.add(PreparedHeaderBlock(surahNumber: blockSurah));
          announcedSurahs.add(blockSurah);
        }

        if (shouldInsertBismillah) {
          mergedBlocks.add(const PreparedBismillahBlock());
        }

        lastTextSurah = blockSurah;
      }

      mergedBlocks.add(block);
    }

    final List<PreparedPageBlock> blocksWithSpacing = _applySurahLeadSpacing(
      mergedBlocks,
      page.metrics,
    );

    return PreparedQuranPage(metrics: page.metrics, blocks: blocksWithSpacing);
  }

  List<PreparedPageBlock> _applySurahLeadSpacing(
    List<PreparedPageBlock> source,
    QuranLayoutMetrics metrics,
  ) {
    if (source.isEmpty) return source;

    final double lineHeight = metrics.fontSize * metrics.fontHeight;
    final double headerToBismillahGap = (lineHeight * 0.08)
        .clamp(3.0, 6.0)
        .toDouble();
    final double bismillahToTextGap = (lineHeight * 0.05)
        .clamp(2.0, 4.0)
        .toDouble();

    final List<PreparedPageBlock> result = <PreparedPageBlock>[];

    int nextMeaningfulIndex(int start) {
      for (var i = start; i < source.length; i++) {
        if (source[i] is! PreparedSpacerBlock) return i;
      }
      return -1;
    }

    for (var i = 0; i < source.length; i++) {
      final PreparedPageBlock block = source[i];
      result.add(block);

      final int nextMeaningful = nextMeaningfulIndex(i + 1);
      if (nextMeaningful == -1) continue;

      final PreparedPageBlock nextBlock = source[nextMeaningful];
      final bool hasSpacerBetween = (i + 1) != nextMeaningful;

      if (block is PreparedHeaderBlock &&
          nextBlock is PreparedBismillahBlock &&
          !hasSpacerBetween) {
        result.add(PreparedSpacerBlock(height: headerToBismillahGap));
        continue;
      }

      if (block is PreparedBismillahBlock &&
          nextBlock is PreparedTextBlock &&
          !hasSpacerBetween) {
        result.add(PreparedSpacerBlock(height: bismillahToTextGap));
      }
    }

    return result;
  }

  bool _needsStandaloneBismillah(int surahNumber) {
    // Standalone Bismillah is omitted for Al-Fatihah and At-Tawbah.
    return surahNumber != 1 && surahNumber != 9;
  }

  void _consumeTrailingSpacerSlots(
    List<PreparedPageBlock> blocks, {
    required int slotCount,
  }) {
    var removed = 0;
    while (blocks.isNotEmpty && removed < slotCount) {
      final PreparedPageBlock lastBlock = blocks.last;
      if (lastBlock is! PreparedSpacerBlock) {
        break;
      }
      blocks.removeLast();
      removed++;
    }
  }

  bool _lastMeaningfulBlockIsBismillah(List<PreparedPageBlock> blocks) {
    for (var i = blocks.length - 1; i >= 0; i--) {
      final PreparedPageBlock block = blocks[i];
      if (block is PreparedSpacerBlock) continue;
      return block is PreparedBismillahBlock;
    }
    return false;
  }
}

class _ReelTopBar extends StatelessWidget {
  const _ReelTopBar({
    required this.pageHeight,
    required this.surahNames,
    required this.juzNumber,
  });

  final double pageHeight;
  final List<String> surahNames;
  final int juzNumber;

  @override
  Widget build(BuildContext context) {
    final double height = (pageHeight * 0.042).clamp(28.0, 42.0).toDouble();

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                surahNames.join(' '),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _QcfPage._frameTextColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'الجزء ${convertToArabicNumber(juzNumber.toString())}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B7355),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ReelBottomBar extends StatelessWidget {
  const _ReelBottomBar({
    required this.pageWidth,
    required this.pageHeight,
    required this.pageNumber,
    required this.hizbNumber,
  });

  final double pageWidth;
  final double pageHeight;
  final int pageNumber;
  final int hizbNumber;

  @override
  Widget build(BuildContext context) {
    final double circleSize = (pageHeight * 0.05).clamp(34.0, 46.0).toDouble();

    return Container(
      margin: EdgeInsets.fromLTRB(
        pageWidth * 0.04,
        pageHeight * 0.006,
        pageWidth * 0.04,
        pageHeight * 0.010,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: (pageHeight * 0.002).clamp(2.0, 6.0).toDouble(),
      ),
      decoration: BoxDecoration(
        color: _QcfPage._frameSurfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _QcfPage._frameAccentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _ReelPageNumberBadge(size: circleSize, pageNumber: pageNumber),
          const Spacer(),
          Text(
            'الحزب ${convertToArabicNumber(hizbNumber.toString())}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ReelPageNumberBadge extends StatelessWidget {
  const _ReelPageNumberBadge({required this.size, required this.pageNumber});

  final double size;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _QcfPage._frameAccentColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: _QcfPage._frameAccentColor),
      ),
      child: Text(
        convertToArabicNumber(pageNumber.toString()),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D4037),
        ),
      ),
    );
  }
}

// Shared across instances: overlays are always hidden during share capture.
final ValueNotifier<bool> _kHiddenOverlaysListenable = ValueNotifier<bool>(
  false,
);
