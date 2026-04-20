import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_image/core/constants/surah_header_constants.dart' as qi;
import 'package:quran_image/core/di/dependency_injection.dart' as qi_di;
import 'package:quran_image/quran_image.dart' as qi;

import '../../domain/entities/mushaf_render_style.dart';
import '../utils/video_page_specs.dart';

/// Renders a single mushaf page for video generation.
///
/// Abstracts over the two possible rendering strategies (high-fidelity
/// page images vs dynamic text layout). Concrete implementations receive
/// the services they need at construction time, so the widget tree never
/// touches a service locator.
abstract class MushafPageRenderer {
  const MushafPageRenderer();

  /// Returns the implementation for [style], wiring in any required
  /// dependencies. Call this at the composition root (screen/widget
  /// builder) so widget `build` methods stay pure.
  factory MushafPageRenderer.forStyle(MushafRenderStyle style) {
    switch (style) {
      case MushafRenderStyle.highFidelity:
        return HighFidelityMushafPageRenderer(
          markerRepository: qi_di.sl<qi.VerseMarkerRepository>(),
          headerRepository: qi_di.sl<qi.SurahHeaderRepository>(),
          imageCacheRepository: qi_di.sl<qi.QuranImageCacheRepository>(),
        );
      case MushafRenderStyle.dynamicLayout:
        return const DynamicLayoutMushafPageRenderer();
    }
  }

  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color textColor,
    required Color pageBackgroundColor,
  });
}

/// Renders a mushaf page using the high-fidelity line images shipped with
/// the `quran_image` package. Produces pixel-accurate mushaf pages but does
/// not respond to viewport width.
class HighFidelityMushafPageRenderer extends MushafPageRenderer {
  const HighFidelityMushafPageRenderer({
    required this.markerRepository,
    required this.headerRepository,
    required this.imageCacheRepository,
  });

  final qi.VerseMarkerRepository markerRepository;
  final qi.SurahHeaderRepository headerRepository;
  final qi.QuranImageCacheRepository imageCacheRepository;

  @override
  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color textColor,
    required Color pageBackgroundColor,
  }) {
    return _HighFidelityPage(
      pageSpec: pageSpec,
      markerRepository: markerRepository,
      headerRepository: headerRepository,
      imageCacheRepository: imageCacheRepository,
    );
  }
}

/// Renders a mushaf page using QCF fonts and dynamic text layout from the
/// `quran` package. Responds to viewport width and supports per-verse
/// background colors.
class DynamicLayoutMushafPageRenderer extends MushafPageRenderer {
  const DynamicLayoutMushafPageRenderer();

  @override
  Widget build({
    required BuildContext context,
    required VideoPageSpec pageSpec,
    required int surahNumber,
    required Color? Function(int surah, int verse) verseBackgroundColor,
    required Color textColor,
    required Color pageBackgroundColor,
  }) {
    return _DynamicLayoutPage(
      pageSpec: pageSpec,
      verseBackgroundColor: verseBackgroundColor,
      textColor: textColor,
      pageBackgroundColor: pageBackgroundColor,
    );
  }
}

class _HighFidelityPage extends StatefulWidget {
  const _HighFidelityPage({
    required this.pageSpec,
    required this.markerRepository,
    required this.headerRepository,
    required this.imageCacheRepository,
  });

  final VideoPageSpec pageSpec;
  final qi.VerseMarkerRepository markerRepository;
  final qi.SurahHeaderRepository headerRepository;
  final qi.QuranImageCacheRepository imageCacheRepository;

  @override
  State<_HighFidelityPage> createState() => _HighFidelityPageState();
}

class _HighFidelityPageState extends State<_HighFidelityPage> {
  List<qi.VerseMarkerData> _markers = const <qi.VerseMarkerData>[];
  List<qi.SurahHeaderData> _headers = const <qi.SurahHeaderData>[];
  List<ImageProvider<Object>?> _lineProviders =
      const <ImageProvider<Object>?>[];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didUpdateWidget(_HighFidelityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageSpec.pageNumber != widget.pageSpec.pageNumber) {
      _refreshData();
    }
  }

  void _refreshData() {
    _markers = widget.markerRepository.getMarkersForPage(
      widget.pageSpec.pageNumber,
    );
    _headers = widget.headerRepository.getHeadersForPage(
      widget.pageSpec.pageNumber,
    );
    _lineProviders = List<ImageProvider<Object>?>.generate(
      qi.SurahHeaderConstants.lineCount,
      (index) {
        final path = widget.imageCacheRepository.lineImageFilePath(
          pageNumber: widget.pageSpec.pageNumber,
          oneBasedLineNumber: index + 1,
        );
        if (path == null) return null;
        return qi.buildQuranLineImageProvider(
          imagePath: path,
          cacheWidth: 1080,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        final layoutHeight = constraints.maxHeight;
        // Line-height ratio derived from the Mushaf source images
        // (1440 px page → 232 px line block). Source: quran_image rendering.
        const double lineHeightRatio = 232 / 1440;
        final lineHeight = pageWidth * lineHeightRatio;

        final lastLineIndex = qi.SurahHeaderConstants.lastLineIndex.toDouble();
        final yOffsets = List<double>.generate(
          qi.SurahHeaderConstants.lineCount,
          (index) => (layoutHeight - lineHeight) / lastLineIndex * index,
          growable: false,
        );

        return qi.QuranImageContent(
          pageNumber: widget.pageSpec.pageNumber,
          pageWidth: pageWidth,
          pageHeight: layoutHeight,
          lineHeight: lineHeight,
          yOffsets: yOffsets,
          headers: _headers,
          markers: _markers,
          lineProviders: _lineProviders,
          surahHeaderLayoutPolicy:
              const qi.CalibratedSurahHeaderBannerLayoutPolicy(),
          imageCacheRepository: widget.imageCacheRepository,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          backgroundColor: Colors.transparent,
        );
      },
    );
  }
}

class _DynamicLayoutPage extends StatelessWidget {
  const _DynamicLayoutPage({
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

// Shared across instances: overlays are always hidden during video capture.
final ValueNotifier<bool> _kHiddenOverlaysListenable = ValueNotifier<bool>(
  false,
);
