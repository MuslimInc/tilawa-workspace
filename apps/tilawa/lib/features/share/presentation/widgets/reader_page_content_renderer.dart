import 'package:flutter/material.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../../../quran_reader/presentation/theme/quran_reader_theme.dart';

final ValueNotifier<bool> _hiddenReaderPageOverlays = ValueNotifier<bool>(
  false,
);

/// Dedicated capture/preview surface for a single Mushaf page.
///
/// This mirrors the Quran reader page content without relying on the live
/// `PageView` route underneath the share composer.
class ReaderPageContentRenderer extends StatelessWidget {
  const ReaderPageContentRenderer({
    super.key,
    required this.pageNumber,
    this.uiTextDirection = TextDirection.ltr,
  });

  final int pageNumber;
  final TextDirection uiTextDirection;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: readerTheme.pageBackground),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Explicitly calculate metrics and prepare the page data so PageContent
          // does not fall back to a "NO DATA" blank state.
          final metrics = StandardQuranLayoutStrategy().calculateMetrics(
            context,
            constraints,
            pageNumber,
            quranQcfLocator<MushafService>(),
          );

          return ListenableBuilder(
            listenable: quranQcfLocator<QuranFontService>(),
            builder: (context, _) {
              final bool isFontLoaded = quranQcfLocator<QuranFontService>()
                  .isFontLoaded(pageNumber);

              if (!isFontLoaded) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              final preparedPage =
                  quranQcfLocator<QuranPagePreparationService>().preparePage(
                    pageNumber: pageNumber,
                    metrics: metrics,
                    viewportWidth: constraints.maxWidth,
                    textColor: readerTheme.textColor,
                    mushafService: quranQcfLocator<MushafService>(),
                  );

              return MediaQuery(
                data: mediaQuery.copyWith(
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: PageContent(
                    mushafService: quranQcfLocator<MushafService>(),
                    pageSnapshotService: quranQcfLocator<PageSnapshotService>(),
                    pageNumber: pageNumber,
                    preparedPage: preparedPage,
                    textColor: readerTheme.textColor,
                    pageBackgroundColor: readerTheme.pageBackground,
                    headerImageFilter: readerTheme.headerImageFilter,
                    headerTextColor: readerTheme.headerTextColor,
                    headerFontSizeMultiplier: 0.57,
                    uiTextDirection: uiTextDirection,
                    showOverlaysListenable: _hiddenReaderPageOverlays,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
