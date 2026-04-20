import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
// ignore: implementation_imports
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../utils/video_page_specs.dart';
import 'mushaf_page_renderer.dart';

/// A Quran-focused 9:16 canvas used for video generation.
class VideoContentRenderer extends StatefulWidget {
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
      width: 1080,
      height: 1920,
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
    final normalizedReciterName = reciterName?.trim();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _VideoPalette.deepGreen,
            _VideoPalette.forestGreen,
            _VideoPalette.tealGreen,
          ],
        ),
      ),
      child: Stack(
        children: [
          if (!isCapturing)
            const Positioned(
              top: -140,
              right: -60,
              child: TilawaAmbientOrb(
                size: 320,
                color: _VideoPalette.mint,
                opacity: 0.12,
              ),
            ),
          if (!isCapturing)
            const Positioned(
              bottom: -120,
              left: -50,
              child: TilawaAmbientOrb(
                size: 260,
                color: _VideoPalette.gold,
                opacity: 0.12,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: _VideoPalette.gold.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: .stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _VideoMushafPage(
                        surahNumber: surahNumber,
                        pageSpec: pageSpec,
                        pageRenderer: pageRenderer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _VideoFooter(reciterName: normalizedReciterName),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    return _VideoPalette.gold.withValues(alpha: 0.24);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFF8ED)),
      child: pageRenderer.build(
        context: context,
        pageSpec: pageSpec,
        surahNumber: surahNumber,
        verseBackgroundColor: _verseBackgroundColor,
        textColor: _VideoPalette.ink.withValues(alpha: 0.96),
        pageBackgroundColor: const Color(0xFFFFF8ED),
      ),
    );
  }
}

class _VideoFooter extends StatelessWidget {
  const _VideoFooter({required this.reciterName});

  final String? reciterName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        const _FooterPill(icon: Icons.auto_stories_rounded, label: 'Tilawa'),
        if (reciterName != null && reciterName!.isNotEmpty)
          _FooterPill(
            icon: Icons.multitrack_audio_rounded,
            label: reciterName!,
          ),
      ],
    );
  }
}

class _FooterPill extends StatelessWidget {
  const _FooterPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _VideoPalette.deepGreen.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _VideoPalette.gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _VideoPalette.deepGreen.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Video card labels are always Arabic — the Mushaf is an Arabic artifact.
abstract final class _VideoStrings {
  static const String ayah = 'آية';
  static const String ayahs = 'الآيات';
  static const String mushafPage = 'صفحة المصحف';
}

abstract final class _VideoPalette {
  static const Color deepGreen = Color(0xFF0B342E);
  static const Color forestGreen = Color(0xFF145247);
  static const Color tealGreen = Color(0xFF1E6558);
  static const Color gold = Color(0xFFE1C17B);
  static const Color mint = Color(0xFF8FDFC0);
  static const Color cream = Color(0xFFF6F0DF);
  static const Color parchment = Color(0xFFF7F1E1);
  static const Color warmParchment = Color(0xFFEDDFC1);
  static const Color ink = Color(0xFF1E1B16);
}
