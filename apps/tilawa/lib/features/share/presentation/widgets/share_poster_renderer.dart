import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../../../quran_reader/presentation/theme/quran_reader_theme.dart';
import '../utils/selected_quran_range_page.dart';
import '../utils/share_ayah_range_utils.dart';

final ValueNotifier<bool> _hiddenSharePosterOverlays = ValueNotifier<bool>(
  false,
);

const double _sharePosterViewportOverflowGuard = 4.0;
const double _sharePosterMaxWidthToHeightRatio = 0.56;
const double _sharePosterHeaderFontSizeMultiplier = 0.57;

/// Renders the selected ayah range using prepared QCF page blocks.
///
/// The screenshot path builds a dedicated selected-range composition instead
/// of cropping the source Mushaf page at the original vertical offset.
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
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height;
        final pageHeight = availableHeight > _sharePosterViewportOverflowGuard
            ? availableHeight - _sharePosterViewportOverflowGuard
            : availableHeight;
        final pageWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(
                0.0,
                pageHeight * _sharePosterMaxWidthToHeightRatio,
              )
            : pageHeight * _sharePosterMaxWidthToHeightRatio;
        final pageViewportSize = Size(pageWidth, pageHeight);
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
                  viewportWidth: pageWidth,
                  textColor: readerTheme.textColor,
                  mushafService: quranQcfLocator<MushafService>(),
                );

            final selectedComposition = buildSelectedQuranRangeComposition(
              sourcePage: preparedPage,
              surahNumber: surahNumber,
              fromAyah: ayahRange.fromAyah,
              toAyah: ayahRange.toAyah,
              viewportSize: pageViewportSize,
              headerFontSizeMultiplier: _sharePosterHeaderFontSizeMultiplier,
            );

            if (selectedComposition == null) {
              return const SizedBox.shrink();
            }

            final compositionHeight = selectedComposition.estimatedHeight.clamp(
              0.0,
              pageHeight,
            ).toDouble();

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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: pageWidth,
                      height: compositionHeight,
                      child: PageContent(
                        mushafService: quranQcfLocator<MushafService>(),
                        pageSnapshotService:
                            quranQcfLocator<PageSnapshotService>(),
                        pageNumber: pageNumber,
                        preparedPage: selectedComposition.page,
                        textColor: readerTheme.textColor,
                        pageBackgroundColor: readerTheme.pageBackground,
                        headerImageFilter: readerTheme.headerImageFilter,
                        headerTextColor: readerTheme.headerTextColor,
                        headerFontSizeMultiplier:
                            _sharePosterHeaderFontSizeMultiplier,
                        uiTextDirection: TextDirection.rtl,
                        showOverlaysListenable: _hiddenSharePosterOverlays,
                        alignTextToTop: true,
                        showSpecialBlocks: true,
                        viewportSize: pageViewportSize,
                        enableSnapshots: false,
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
