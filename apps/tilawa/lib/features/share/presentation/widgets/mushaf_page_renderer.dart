import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

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
/// [quran.QuranFontService] for on-demand font loading and
/// [quran.QuranPagePreparationService] for layout.
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
      verseBackgroundColor: verseBackgroundColor,
      textColor: textColor,
      pageBackgroundColor: pageBackgroundColor,
    );
  }
}

class _QcfPage extends StatelessWidget {
  const _QcfPage({
    required this.pageSpec,
    required this.verseBackgroundColor,
    required this.textColor,
    required this.pageBackgroundColor,
  });

  final VideoPageSpec pageSpec;
  final Color? Function(int surah, int verse) verseBackgroundColor;
  final Color textColor;
  final Color pageBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = quran.StandardQuranLayoutStrategy().calculateMetrics(
          context,
          constraints,
          pageSpec.pageNumber,
        );

        return ListenableBuilder(
          listenable: quran.QuranFontService.instance,
          builder: (context, _) {
            final bool isFontLoaded = quran.QuranFontService.instance
                .isFontLoaded(pageSpec.pageNumber);

            if (!isFontLoaded) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final preparedPage = quran.QuranPagePreparationService.instance
                .preparePage(
                  pageNumber: pageSpec.pageNumber,
                  metrics: metrics,
                  viewportWidth: constraints.maxWidth,
                  textColor: textColor,
                  verseBackgroundColor: verseBackgroundColor,
                );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: quran.PageContent(
                pageNumber: pageSpec.pageNumber,
                preparedPage: preparedPage,
                textColor: textColor,
                pageBackgroundColor: pageBackgroundColor,
                verseBackgroundColor: verseBackgroundColor,
                uiTextDirection: TextDirection.rtl,
                showOverlaysListenable: _kHiddenOverlaysListenable,
              ),
            );
          },
        );
      },
    );
  }
}

// Shared across instances: overlays are always hidden during share capture.
final ValueNotifier<bool> _kHiddenOverlaysListenable = ValueNotifier<bool>(
  false,
);
