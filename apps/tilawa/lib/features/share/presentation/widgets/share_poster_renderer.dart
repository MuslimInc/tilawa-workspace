import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../../../quran_reader/presentation/theme/quran_reader_theme.dart';
import '../utils/share_ayah_range_utils.dart';

final ValueNotifier<bool> _hiddenSharePosterOverlays = ValueNotifier<bool>(
  false,
);

/// Renders the selected ayah slice using prepared QCF page blocks.
///
/// This keeps the original Mushaf line geometry and font size instead of
/// reflowing the selected verses into a custom poster composition.
class SharePosterRenderer extends StatelessWidget {
  const SharePosterRenderer({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.reciterName,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final String? reciterName;

  @override
  Widget build(BuildContext context) {
    final ayahRange = normalizeShareAyahRange(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
    final pageNumber = getPageNumber(surahNumber, ayahRange.fromAyah);
    final mediaQuery = MediaQuery.of(context);
    final readerTheme = QuranReaderTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height;
        final pageViewportSize = Size(constraints.maxWidth, pageHeight);
        final pageConstraints = BoxConstraints.tight(pageViewportSize);

        final metrics = StandardQuranLayoutStrategy().calculateMetrics(
          context,
          pageConstraints,
          pageNumber,
          quranQcfLocator<MushafService>(),
        );

        return ListenableBuilder(
          listenable: quranQcfLocator<QuranFontService>(),
          builder: (context, _) {
            final isFontLoaded = quranQcfLocator<QuranFontService>()
                .isFontLoaded(pageNumber);

            if (!isFontLoaded) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final preparedPage = quranQcfLocator<QuranPagePreparationService>()
                .preparePage(
                  pageNumber: pageNumber,
                  metrics: metrics,
                  viewportWidth: constraints.maxWidth,
                  textColor: readerTheme.textColor,
                  mushafService: quranQcfLocator<MushafService>(),
                );

            final cropWindow = _selectedCropWindow(
              preparedPage.blocks,
              metrics: metrics,
              surahNumber: surahNumber,
              fromAyah: ayahRange.fromAyah,
              toAyah: ayahRange.toAyah,
            );

            if (cropWindow == null) {
              return const SizedBox.shrink();
            }

            return DecoratedBox(
              decoration: BoxDecoration(color: readerTheme.pageBackground),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ClipRect(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: cropWindow.height.clamp(0.0, pageHeight),
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minWidth: constraints.maxWidth,
                        maxWidth: constraints.maxWidth,
                        minHeight: pageHeight,
                        maxHeight: pageHeight,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            -(metrics.padding.top + cropWindow.top),
                          ),
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: pageHeight,
                            child: PageContent(
                              mushafService: quranQcfLocator<MushafService>(),
                              pageSnapshotService:
                                  quranQcfLocator<PageSnapshotService>(),
                              pageNumber: pageNumber,
                              preparedPage: preparedPage,
                              textColor: readerTheme.textColor,
                              verseTextColor: (verseSurahNumber, verseNumber) {
                                final isSelected =
                                    verseSurahNumber == surahNumber &&
                                    verseNumber >= ayahRange.fromAyah &&
                                    verseNumber <= ayahRange.toAyah;
                                return isSelected
                                    ? readerTheme.textColor
                                    : Colors.transparent;
                              },
                              pageBackgroundColor: readerTheme.pageBackground,
                              headerImageFilter: readerTheme.headerImageFilter,
                              headerTextColor: readerTheme.headerTextColor,
                              headerFontSizeMultiplier: 0.57,
                              uiTextDirection: TextDirection.rtl,
                              showOverlaysListenable:
                                  _hiddenSharePosterOverlays,
                              alignTextToTop: true,
                              showSpecialBlocks: false,
                              viewportSize: pageViewportSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

_SelectionCropWindow? _selectedCropWindow(
  List<PreparedPageBlock> blocks, {
  required QuranLayoutMetrics metrics,
  required int surahNumber,
  required int fromAyah,
  required int toAyah,
}) {
  double yOffset = 0;
  double? top;
  double? bottom;
  var previousWasTextBlock = false;

  for (final block in blocks) {
    if (block is PreparedHeaderBlock || block is PreparedBismillahBlock) {
      previousWasTextBlock = false;
      continue;
    }

    if (block is PreparedSpacerBlock) {
      yOffset += block.height;
      previousWasTextBlock = false;
      continue;
    }

    if (block is! PreparedTextBlock) {
      continue;
    }

    if (previousWasTextBlock) {
      yOffset += metrics.lineSpacing;
    }

    final blockTop = yOffset;
    final blockBottom = blockTop + block.painter.height;
    final hasSelectedVerse = block.metadata.any(
      (word) =>
          word.surah == surahNumber &&
          word.verse >= fromAyah &&
          word.verse <= toAyah,
    );

    if (hasSelectedVerse) {
      top ??= blockTop;
      bottom = blockBottom;
    }

    yOffset = blockBottom;
    previousWasTextBlock = true;
  }

  if (top == null || bottom == null || bottom <= top) {
    return null;
  }

  return _SelectionCropWindow(top: top, height: bottom - top);
}

class _SelectionCropWindow {
  const _SelectionCropWindow({required this.top, required this.height});

  final double top;
  final double height;
}
