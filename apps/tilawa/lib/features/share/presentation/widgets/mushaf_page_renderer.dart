import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';

import '../utils/video_page_specs.dart';
import 'video_reel_design.dart';

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
    required Color? Function(int surah, int verse) verseTextColor,
    required Color textColor,
    required Color pageBackgroundColor,
    bool isCapturing = false,
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

  static const int _alFatihahSurahNumber = 1;
  static const int _atTawbahSurahNumber = 9;

  @override
  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color? Function(int surah, int verse) verseTextColor,
    required Color textColor,
    required Color pageBackgroundColor,
    bool isCapturing = false,
  }) {
    return _QcfPage(
      pageSpec: pageSpec,
      surahNumber: surahNumber,
      verseBackgroundColor: verseBackgroundColor,
      verseTextColor: verseTextColor,
      textColor: textColor,
      pageBackgroundColor: pageBackgroundColor,
      isCapturing: isCapturing,
    );
  }
}

class _QcfPage extends StatefulWidget {
  const _QcfPage({
    required this.pageSpec,
    required this.surahNumber,
    required this.verseBackgroundColor,
    required this.verseTextColor,
    required this.textColor,
    required this.pageBackgroundColor,
    required this.isCapturing,
  });

  final VideoPageSpec pageSpec;
  final int surahNumber;
  final Color? Function(int surah, int verse) verseBackgroundColor;
  final Color? Function(int surah, int verse) verseTextColor;
  final Color textColor;
  final Color pageBackgroundColor;
  final bool isCapturing;

  @override
  State<_QcfPage> createState() => _QcfPageState();
}

class _QcfPageState extends State<_QcfPage> {
  _PreparedVideoPageCacheKey? _preparedPageKey;
  PreparedQuranPage? _preparedPage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mushafService = quranQcfLocator<MushafService>();
        final PageMetadata meta = mushafService.getPageMetadata(
          widget.pageSpec.pageNumber,
        );
        final bool isArabic = context.l10n.localeName == 'ar';
        final List<String> surahNames = meta.surahNumbers
            .map(isArabic ? getSurahNameArabic : getSurahNameEnglish)
            .toList(growable: false);

        return ListenableBuilder(
          listenable: quranQcfLocator<QuranFontService>(),
          builder: (context, _) {
            final fontService = quranQcfLocator<QuranFontService>();
            final bool isFontLoaded = fontService.isFontLoaded(
              widget.pageSpec.pageNumber,
            );

            if (!isFontLoaded) {
              // Actively kick off loading so the ListenableBuilder is notified
              // when done. Safe to call repeatedly — the service deduplicates
              // in-flight requests.
              fontService.ensureSingleFontLoaded(widget.pageSpec.pageNumber);
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
                              widget.pageSpec.pageNumber,
                              mushafService,
                            );
                        final cacheKey = _PreparedVideoPageCacheKey(
                          pageNumber: widget.pageSpec.pageNumber,
                          surahNumber: widget.surahNumber,
                          fromAyah: widget.pageSpec.fromAyah,
                          toAyah: widget.pageSpec.toAyah,
                          fontSize: metrics.fontSize,
                          fontHeight: metrics.fontHeight,
                          viewportWidth: bodyConstraints.maxWidth,
                          textColorValue: widget.textColor.toARGB32(),
                        );
                        PreparedQuranPage? fixedPreparedPage =
                            _preparedPageKey == cacheKey ? _preparedPage : null;
                        if (fixedPreparedPage == null) {
                          final preparedPage =
                              quranQcfLocator<QuranPagePreparationService>()
                                  .preparePage(
                                    pageNumber: widget.pageSpec.pageNumber,
                                    metrics: metrics,
                                    viewportWidth: bodyConstraints.maxWidth,
                                    textColor: widget.textColor,
                                    verseBackgroundColor:
                                        widget.verseBackgroundColor,
                                    mushafService: mushafService,
                                  );
                          fixedPreparedPage = _injectMissingSurahHeaders(
                            preparedPage,
                          );
                          _preparedPageKey = cacheKey;
                          _preparedPage = fixedPreparedPage;
                        }

                        return PageContent(
                          mushafService: mushafService,
                          pageSnapshotService:
                              quranQcfLocator<PageSnapshotService>(),
                          pageNumber: widget.pageSpec.pageNumber,
                          preparedPage: fixedPreparedPage,
                          textColor: widget.textColor,
                          pageBackgroundColor: widget.pageBackgroundColor,
                          alignTextToTop: true,
                          verseBackgroundColor: widget.verseBackgroundColor,
                          verseTextColor: widget.verseTextColor,
                          showSpecialBlocks: false,
                          uiTextDirection: TextDirection.rtl,
                          showOverlaysListenable: _kHiddenOverlaysListenable,
                          viewportSize: Size(
                            bodyConstraints.maxWidth,
                            bodyConstraints.maxHeight,
                          ),
                          enableSnapshots: !widget.isCapturing,
                          isCapturing: widget.isCapturing,
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
    final double headerToBismillahGap =
        (lineHeight * VideoReelDesign.surahHeaderToBismillahGapFactor)
            .clamp(
              VideoReelDesign.surahHeaderToBismillahMinGap,
              VideoReelDesign.surahHeaderToBismillahMaxGap,
            )
            .toDouble();
    final double bismillahToTextGap =
        (lineHeight * VideoReelDesign.bismillahToTextGapFactor)
            .clamp(
              VideoReelDesign.bismillahToTextMinGap,
              VideoReelDesign.bismillahToTextMaxGap,
            )
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
    return surahNumber != QcfMushafPageRenderer._alFatihahSurahNumber &&
        surahNumber != QcfMushafPageRenderer._atTawbahSurahNumber;
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

class _PreparedVideoPageCacheKey extends Equatable {
  static const int _dimensionPrecision = 100;

  _PreparedVideoPageCacheKey({
    required this.pageNumber,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    required double fontSize,
    required double fontHeight,
    required double viewportWidth,
    required this.textColorValue,
  }) : fontSizeKey = (fontSize * _dimensionPrecision).round(),
       fontHeightKey = (fontHeight * _dimensionPrecision).round(),
       viewportWidthKey = (viewportWidth * _dimensionPrecision).round();

  final int pageNumber;
  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final int fontSizeKey;
  final int fontHeightKey;
  final int viewportWidthKey;
  final int textColorValue;

  @override
  List<Object> get props => [
    pageNumber,
    surahNumber,
    fromAyah,
    toAyah,
    fontSizeKey,
    fontHeightKey,
    viewportWidthKey,
    textColorValue,
  ];
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
    final bool isArabic = context.l10n.localeName == 'ar';
    final palette = VideoReelPalette.fromContext(context);
    final double height = (pageHeight * VideoReelDesign.topBarHeightFactor)
        .clamp(VideoReelDesign.topBarMinHeight, VideoReelDesign.topBarMaxHeight)
        .toDouble();
    final String localizedJuzNumber = _localizedQuranNumber(context, juzNumber);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VideoReelDesign.topBarHorizontalPadding,
        ),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  surahNames.join(' '),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: VideoReelDesign.topBarTitleFontSize,
                    fontWeight: FontWeight.w600,
                    color: palette.frameTextColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: VideoReelDesign.topBarGap),
              Text(
                '${context.l10n.juzPart} $localizedJuzNumber',
                style: TextStyle(
                  fontSize: VideoReelDesign.topBarMetaFontSize,
                  fontWeight: FontWeight.w500,
                  color: palette.frameSecondaryTextColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
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
    final bool isArabic = context.l10n.localeName == 'ar';
    final palette = VideoReelPalette.fromContext(context);
    final double circleSize = (pageHeight * VideoReelDesign.pageBadgeSizeFactor)
        .clamp(
          VideoReelDesign.pageBadgeMinSize,
          VideoReelDesign.pageBadgeMaxSize,
        )
        .toDouble();
    final String localizedHizbNumber = _localizedQuranNumber(
      context,
      hizbNumber,
    );

    return Container(
      margin: EdgeInsets.fromLTRB(
        pageWidth * VideoReelDesign.bottomBarHorizontalMarginFactor,
        pageHeight * VideoReelDesign.bottomBarTopMarginFactor,
        pageWidth * VideoReelDesign.bottomBarHorizontalMarginFactor,
        pageHeight * VideoReelDesign.bottomBarBottomMarginFactor,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: VideoReelDesign.bottomBarHorizontalPadding,
        vertical: (pageHeight * VideoReelDesign.bottomBarVerticalPaddingFactor)
            .clamp(
              VideoReelDesign.bottomBarMinVerticalPadding,
              VideoReelDesign.bottomBarMaxVerticalPadding,
            )
            .toDouble(),
      ),
      decoration: BoxDecoration(
        color: palette.frameSurfaceColor,
        borderRadius: BorderRadius.circular(VideoReelDesign.bottomBarRadius),
        border: Border.all(
          color: palette.frameAccentColor.withValues(
            alpha: VideoReelDesign.bottomBarBorderAlpha,
          ),
        ),
      ),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            _ReelPageNumberBadge(size: circleSize, pageNumber: pageNumber),
            const Spacer(),
            Text(
              '${context.l10n.hizb} $localizedHizbNumber',
              style: TextStyle(
                fontSize: VideoReelDesign.bottomBarMetaFontSize,
                fontWeight: FontWeight.bold,
                color: palette.frameStrongTextColor,
              ),
            ),
          ],
        ),
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
    final palette = VideoReelPalette.fromContext(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(VideoReelDesign.pageBadgePadding),
      decoration: BoxDecoration(
        color: palette.frameAccentColor.withValues(
          alpha: VideoReelDesign.pageBadgeAccentAlpha,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: palette.frameAccentColor),
      ),
      child: Text(
        _localizedQuranNumber(context, pageNumber),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: palette.frameStrongTextColor,
        ),
      ),
    );
  }
}

String _localizedQuranNumber(BuildContext context, int value) {
  final String number = value.toString();
  return context.l10n.localeName == 'ar'
      ? convertToArabicNumber(number)
      : number;
}

// Shared across instances: overlays are always hidden during share capture.
final ValueNotifier<bool> _kHiddenOverlaysListenable = ValueNotifier<bool>(
  false,
);
