import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../utils/surah_header_policy.dart';
import '../utils/video_page_specs.dart';
import 'mushaf_page_renderer.dart';
import 'video_reel_design.dart';

enum VideoCompositionMode { edit, review, capture }

@immutable
class VideoCompositionSpec extends Equatable {
  factory VideoCompositionSpec({
    required int surahNumber,
    required VideoPageSpec pageSpec,
    int pageIndex = 0,
    int totalPages = 1,
    String? reciterName,
    VideoCompositionMode mode = VideoCompositionMode.edit,
    String localeName = 'en',
    Color? backgroundColor,
    double canvasWidth = reelCanvasWidth,
    double canvasHeight = reelCanvasHeight,
    double safeZoneTopFraction = reelSafeZoneTopFraction,
    double safeZoneBottomFraction = reelSafeZoneBottomFraction,
  }) {
    final surahHeaderDecision = decideSurahHeader(
      surahNumber: surahNumber,
      selectionTouchesOpeningAyah:
          pageSpec.fromAyah <= 1 && pageSpec.toAyah >= 1,
      isInitialSelection: pageSpec.isInitialSelection,
    );

    return VideoCompositionSpec._(
      surahNumber: surahNumber,
      pageSpec: pageSpec,
      pageIndex: pageIndex,
      totalPages: totalPages,
      reciterName: reciterName,
      mode: mode,
      localeName: localeName,
      backgroundColor: backgroundColor,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      safeZoneTopFraction: safeZoneTopFraction,
      safeZoneBottomFraction: safeZoneBottomFraction,
      surahHeaderDecision: surahHeaderDecision,
    );
  }

  const VideoCompositionSpec._({
    required this.surahNumber,
    required this.pageSpec,
    required this.pageIndex,
    required this.totalPages,
    required this.reciterName,
    required this.mode,
    required this.localeName,
    required this.backgroundColor,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.safeZoneTopFraction,
    required this.safeZoneBottomFraction,
    required this.surahHeaderDecision,
  });

  final int surahNumber;
  final VideoPageSpec pageSpec;
  final int pageIndex;
  final int totalPages;
  final String? reciterName;
  final VideoCompositionMode mode;
  final String localeName;
  final Color? backgroundColor;
  final double canvasWidth;
  final double canvasHeight;
  final double safeZoneTopFraction;
  final double safeZoneBottomFraction;
  final SurahHeaderDecision surahHeaderDecision;

  bool get isCapturing => mode == VideoCompositionMode.capture;

  bool get showSafeZoneGuides => mode == VideoCompositionMode.edit;

  @override
  List<Object?> get props => [
    surahNumber,
    pageSpec.pageNumber,
    pageSpec.fromAyah,
    pageSpec.toAyah,
    pageSpec.isInitialSelection,
    pageIndex,
    totalPages,
    reciterName,
    mode,
    localeName,
    backgroundColor,
    canvasWidth,
    canvasHeight,
    safeZoneTopFraction,
    safeZoneBottomFraction,
    surahHeaderDecision.includeBanner,
    surahHeaderDecision.includeBismillah,
    surahHeaderDecision.surahNumber,
    surahHeaderDecision.reason,
  ];
}

class VideoComposition extends StatelessWidget {
  const VideoComposition({super.key, required this.spec, this.pageRenderer});

  static const Key canvasKey = ValueKey<String>('video_composition_canvas');
  static const Key safeZoneGuidesKey = ValueKey<String>(
    'video_composition_safe_zone_guides',
  );

  final VideoCompositionSpec spec;
  final MushafPageRenderer? pageRenderer;

  @override
  Widget build(BuildContext context) {
    final palette = VideoReelPalette.fromContext(context);
    final Color backgroundColor =
        spec.backgroundColor ?? palette.mushafBackgroundColor;
    final renderer = pageRenderer ?? MushafPageRenderer.defaultRenderer();

    return SizedBox(
      key: canvasKey,
      width: spec.canvasWidth,
      height: spec.canvasHeight,
      child: ColoredBox(
        color: backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            renderer.build(
              context: context,
              pageSpec: spec.pageSpec,
              surahNumber: spec.surahNumber,
              verseBackgroundColor: (surah, verse) =>
                  _verseBackgroundColor(surah, verse, palette),
              verseTextColor: (surah, verse) =>
                  _verseTextColor(surah, verse, palette),
              textColor: palette.mushafTextColor,
              pageBackgroundColor: backgroundColor,
              isCapturing: spec.isCapturing,
            ),
            if (spec.showSafeZoneGuides)
              IgnorePointer(
                key: safeZoneGuidesKey,
                child: CustomPaint(
                  painter: _SafeZoneGuidesPainter(
                    topFraction: spec.safeZoneTopFraction,
                    bottomFraction: spec.safeZoneBottomFraction,
                    color: palette.frameAccentColor.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _verseBackgroundColor(
    int currentSurah,
    int verseNumber,
    VideoReelPalette palette,
  ) {
    if (currentSurah != spec.surahNumber ||
        verseNumber < spec.pageSpec.fromAyah ||
        verseNumber > spec.pageSpec.toAyah) {
      return null;
    }
    return palette.verseHighlightColor;
  }

  Color? _verseTextColor(
    int currentSurah,
    int verseNumber,
    VideoReelPalette palette,
  ) {
    if (currentSurah == spec.surahNumber &&
        verseNumber >= spec.pageSpec.fromAyah &&
        verseNumber <= spec.pageSpec.toAyah) {
      return palette.mushafTextColor;
    }

    return Colors.transparent;
  }
}

class _SafeZoneGuidesPainter extends CustomPainter {
  const _SafeZoneGuidesPainter({
    required this.topFraction,
    required this.bottomFraction,
    required this.color,
  });

  final double topFraction;
  final double bottomFraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final top = size.height * topFraction;
    final bottom = size.height * (1 - bottomFraction);
    _drawDashedLine(canvas, Offset(0, top), Offset(size.width, top), paint);
    _drawDashedLine(
      canvas,
      Offset(0, bottom),
      Offset(size.width, bottom),
      paint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 18.0;
    const gap = 14.0;
    final distance = (to - from).distance;
    if (distance == 0) return;
    final direction = (to - from) / distance;

    var start = 0.0;
    while (start < distance) {
      final end = (start + dash).clamp(0.0, distance);
      canvas.drawLine(from + direction * start, from + direction * end, paint);
      start += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_SafeZoneGuidesPainter oldDelegate) =>
      topFraction != oldDelegate.topFraction ||
      bottomFraction != oldDelegate.bottomFraction ||
      color != oldDelegate.color;
}
