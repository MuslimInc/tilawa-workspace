import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../utils/video_page_specs.dart';
import 'mushaf_page_renderer.dart';

/// A Quran-focused 9:16 canvas used for video generation.
class VideoContentRenderer extends StatefulWidget {
  /// The target width for video generation (Full HD portrait).
  static const double videoWidth = 1080;

  /// The target height for video generation (Full HD portrait).
  static const double videoHeight = 1920;

  /// The standard 9:16 aspect ratio for reels and shorts.
  static const double aspectRatio = 9 / 16;

  const VideoContentRenderer({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.reciterName,
    this.pageSpecs,
    this.isCapturing = false,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final String? reciterName;
  final List<VideoPageSpec>? pageSpecs;

  /// When `true`, the render tree drops animated/cosmetic layers (ambient
  /// orbs, drop shadow) because those costs are wasted on a still-image
  /// capture — they add build/raster time without any visual payoff in a
  /// 1-frame snapshot.
  final bool isCapturing;

  @override
  State<VideoContentRenderer> createState() => _VideoContentRendererState();
}

class _VideoContentRendererState extends State<VideoContentRenderer> {
  final MushafPageRenderer _pageRenderer = MushafPageRenderer.defaultRenderer();

  @override
  Widget build(BuildContext context) {
    final List<VideoPageSpec> effectivePageSpecs =
        widget.pageSpecs ??
        buildVideoPageSpecs(
          surahNumber: widget.surahNumber,
          fromAyah: widget.fromAyah,
          toAyah: widget.toAyah,
        );

    if (effectivePageSpecs.length == 1) {
      return VideoContentPage(
        surahNumber: widget.surahNumber,
        pageSpec: effectivePageSpecs.single,
        pageIndex: 0,
        totalPages: 1,
        reciterName: widget.reciterName,
        isCapturing: widget.isCapturing,
        pageRenderer: _pageRenderer,
      );
    }

    return SizedBox(
      width: VideoContentRenderer.videoWidth,
      height: VideoContentRenderer.videoHeight,
      child: PageView.builder(
        itemCount: effectivePageSpecs.length,
        itemBuilder: (context, index) {
          return VideoContentPage(
            surahNumber: widget.surahNumber,
            pageSpec: effectivePageSpecs[index],
            pageIndex: index,
            totalPages: effectivePageSpecs.length,
            reciterName: widget.reciterName,
            isCapturing: widget.isCapturing,
            pageRenderer: _pageRenderer,
          );
        },
      ),
    );
  }
}

class VideoContentPage extends StatelessWidget {
  const VideoContentPage({
    super.key,
    required this.surahNumber,
    required this.pageSpec,
    required this.pageIndex,
    required this.totalPages,
    this.reciterName,
    this.isCapturing = false,
    required this.pageRenderer,
  });

  final int surahNumber;
  final VideoPageSpec pageSpec;
  final int pageIndex;
  final int totalPages;
  final String? reciterName;
  final MushafPageRenderer pageRenderer;

  /// Mirrors [VideoContentRenderer.isCapturing] — disables ambient orbs and
  /// the heavy BoxShadow while capturing a frozen frame for FFmpeg.
  final bool isCapturing;

  String get _arabicSurahName => quran.getSurahNameArabic(surahNumber);
  String get _englishSurahName => quran.getSurahNameEnglish(surahNumber);

  String get _ayahRangeLabel => pageSpec.fromAyah == pageSpec.toAyah
      ? '${_VideoStrings.ayah} ${pageSpec.fromAyah}'
      : '${_VideoStrings.ayahs} ${pageSpec.fromAyah} - ${pageSpec.toAyah}';

  String get _mushafPageLabel => totalPages == 1
      ? '${_VideoStrings.mushafPage} ${pageSpec.pageNumber}'
      : '${_VideoStrings.mushafPage} ${pageSpec.pageNumber} • ${pageIndex + 1}/$totalPages';

  @override
  Widget build(BuildContext context) {
    return _VideoMushafPage(
      surahNumber: surahNumber,
      pageSpec: pageSpec,
      pageRenderer: pageRenderer,
    );
  }
}

class _VideoMushafPage extends StatelessWidget {
  const _VideoMushafPage({
    required this.surahNumber,
    required this.pageSpec,
    required this.pageRenderer,
  });

  final int surahNumber;
  final VideoPageSpec pageSpec;
  final MushafPageRenderer pageRenderer;

  Color? _verseBackgroundColor(int currentSurah, int verseNumber) {
    if (currentSurah != surahNumber ||
        verseNumber < pageSpec.fromAyah ||
        verseNumber > pageSpec.toAyah) {
      return null;
    }
    return Colors.orange.withValues(alpha: _VideoLayout.verseHighlightAlpha);
  }

  @override
  Widget build(BuildContext context) {
    return pageRenderer.build(
      context: context,
      pageSpec: pageSpec,
      surahNumber: surahNumber,
      verseBackgroundColor: _verseBackgroundColor,
      textColor: Colors.pink.withValues(alpha: _VideoLayout.textOpacity),
      pageBackgroundColor: _VideoLayout.pageBackgroundColor,
    );
  }
}

abstract final class _VideoLayout {
  static const double orbLargeSize = 320;
  static const double orbMediumSize = 260;
  static const double orbTopOffset = -140;
  static const double orbRightOffset = -60;
  static const double orbBottomOffset = -120;
  static const double orbLeftOffset = -50;

  static const double canvasRadius = 60;
  static const double canvasBorderAlpha = 0.18;

  static const Color pageBackgroundColor = Color(0xFFFFF8ED);
  static const double verseHighlightAlpha = 0.24;
  static const double textOpacity = 0.96;
}

// Video card labels are always Arabic — the Mushaf is an Arabic artifact.
abstract final class _VideoStrings {
  static const String ayah = 'آية';
  static const String ayahs = 'الآيات';
  static const String mushafPage = 'صفحة المصحف';
}
