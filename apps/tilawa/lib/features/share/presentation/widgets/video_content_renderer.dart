import 'package:flutter/material.dart';

import '../../domain/entities/share_video_profile.dart';
import '../utils/video_page_specs.dart';
import 'mushaf_page_renderer.dart';
import 'video_reel_design.dart';

/// A Quran-focused 9:16 canvas used for video generation.
class VideoContentRenderer extends StatefulWidget {
  /// The target width for generated reels.
  ///
  /// Keep this aligned with the video encoder output size so capture does not
  /// lay out and rasterize a larger off-screen surface than the final MP4 uses.
  static const double videoWidth = ShareVideoProfile.outputWidth;

  /// The target height for generated reels.
  static const double videoHeight = ShareVideoProfile.outputHeight;

  /// The standard 9:16 aspect ratio for reels and shorts.
  static const double aspectRatio = ShareVideoProfile.aspectRatio;

  const VideoContentRenderer({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.reciterName,
    this.pageSpecs,
    this.isCapturing = false,
    this.backgroundColor,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final String? reciterName;
  final List<VideoPageSpec>? pageSpecs;
  final Color? backgroundColor;

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
    final Color backgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final List<VideoPageSpec> effectivePageSpecs =
        widget.pageSpecs ??
        buildVideoPageSpecs(
          surahNumber: widget.surahNumber,
          fromAyah: widget.fromAyah,
          toAyah: widget.toAyah,
        );

    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(
        child: effectivePageSpecs.length == 1
            ? VideoContentPage(
                surahNumber: widget.surahNumber,
                pageSpec: effectivePageSpecs.single,
                pageIndex: 0,
                totalPages: 1,
                reciterName: widget.reciterName,
                isCapturing: widget.isCapturing,
                pageRenderer: _pageRenderer,
                backgroundColor: backgroundColor,
              )
            : PageView.builder(
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
                    backgroundColor: backgroundColor,
                  );
                },
              ),
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
    required this.backgroundColor,
  });

  final int surahNumber;
  final VideoPageSpec pageSpec;
  final int pageIndex;
  final int totalPages;
  final String? reciterName;
  final MushafPageRenderer pageRenderer;
  final Color backgroundColor;

  /// Mirrors [VideoContentRenderer.isCapturing] — disables ambient orbs and
  /// the heavy BoxShadow while capturing a frozen frame for FFmpeg.
  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    return _VideoMushafPage(
      surahNumber: surahNumber,
      pageSpec: pageSpec,
      pageRenderer: pageRenderer,
      backgroundColor: backgroundColor,
      isCapturing: isCapturing,
    );
  }
}

class _VideoMushafPage extends StatelessWidget {
  const _VideoMushafPage({
    required this.surahNumber,
    required this.pageSpec,
    required this.pageRenderer,
    required this.backgroundColor,
    required this.isCapturing,
  });

  final int surahNumber;
  final VideoPageSpec pageSpec;
  final MushafPageRenderer pageRenderer;
  final Color backgroundColor;
  final bool isCapturing;

  Color? _verseBackgroundColor(int currentSurah, int verseNumber) {
    if (currentSurah != surahNumber ||
        verseNumber < pageSpec.fromAyah ||
        verseNumber > pageSpec.toAyah) {
      return null;
    }
    return VideoReelDesign.verseHighlightColor;
  }

  Color? _verseTextColor(int currentSurah, int verseNumber) {
    if (currentSurah == surahNumber &&
        verseNumber >= pageSpec.fromAyah &&
        verseNumber <= pageSpec.toAyah) {
      return VideoReelDesign.mushafTextColor;
    }

    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return pageRenderer.build(
      context: context,
      pageSpec: pageSpec,
      surahNumber: surahNumber,
      verseBackgroundColor: _verseBackgroundColor,
      verseTextColor: _verseTextColor,
      textColor: VideoReelDesign.mushafTextColor,
      pageBackgroundColor: backgroundColor,
      isCapturing: isCapturing,
    );
  }
}
