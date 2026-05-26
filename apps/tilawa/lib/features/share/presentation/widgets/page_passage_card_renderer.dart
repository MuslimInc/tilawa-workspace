import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'reader_page_content_renderer.dart';

/// Passage-card variant for pages that contain more than one surah.
///
/// Instead of pretending the page belongs to a single surah/range, this
/// renderer keeps the poster treatment while embedding the actual Mushaf page.
class PagePassageCardRenderer extends StatelessWidget {
  const PagePassageCardRenderer({
    super.key,
    required this.pageNumber,
    required this.arabicSurahNames,
    required this.englishSurahNames,
    this.reciterName,
    this.uiTextDirection = TextDirection.ltr,
  });

  final int pageNumber;
  final String arabicSurahNames;
  final String englishSurahNames;
  final String? reciterName;
  final TextDirection uiTextDirection;

  @override
  Widget build(BuildContext context) {
    final String? normalizedReciterName = reciterName?.trim();

    return SizedBox(
      width: _PagePosterLayout.canvasWidth,
      height: _PagePosterLayout.canvasHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPagePassagePosterColors.deepGreen,
              AppPagePassagePosterColors.forestGreen,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: _PagePosterLayout.topOrbTop,
              right: _PagePosterLayout.topOrbRight,
              child: _PosterOrb(
                size: _PagePosterLayout.topOrbSize,
                color: AppPagePassagePosterColors.mint,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: _PagePosterLayout.bottomOrbBottom,
              left: _PagePosterLayout.bottomOrbLeft,
              child: _PosterOrb(
                size: _PagePosterLayout.bottomOrbSize,
                color: AppPagePassagePosterColors.gold,
                opacity: 0.12,
              ),
            ),
            Padding(
              padding: _PagePosterLayout.outerPadding,
              child: Container(
                padding: _PagePosterLayout.contentPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    _PagePosterLayout.contentRadius,
                  ),
                  border: Border.all(
                    color: AppPagePassagePosterColors.gold.withValues(
                      alpha: 0.42,
                    ),
                    width: 2,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPagePassagePosterColors.parchment,
                      AppPagePassagePosterColors.warmParchment,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const _PosterPill(
                          icon: Icons.auto_stories_rounded,
                          label: 'Tilawa',
                        ),
                        const Spacer(),
                        _PosterPill(
                          icon: Icons.menu_book_rounded,
                          label: 'صفحة المصحف $pageNumber',
                        ),
                      ],
                    ),
                    const SizedBox(height: _PagePosterLayout.headerGap),
                    Text(
                      arabicSurahNames,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: _PagePosterLayout.arabicTitleSize,
                        height: _PagePosterLayout.arabicTitleHeight,
                        fontWeight: FontWeight.w700,
                        color: AppPagePassagePosterColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: _PagePosterLayout.subtitleGap),
                    Text(
                      englishSurahNames.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _PagePosterLayout.englishTitleSize,
                        letterSpacing:
                            _PagePosterLayout.englishTitleLetterSpacing,
                        fontWeight: FontWeight.w600,
                        color: AppPagePassagePosterColors.deepGreen.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    const SizedBox(height: _PagePosterLayout.readerGap),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          _PagePosterLayout.readerFramePadding,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            _PagePosterLayout.readerFrameRadius,
                          ),
                          color: Colors.white.withValues(alpha: 0.42),
                          border: Border.all(
                            color: AppPagePassagePosterColors.gold.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            _PagePosterLayout.readerClipRadius,
                          ),
                          child: ReaderPageContentRenderer(
                            pageNumber: pageNumber,
                            uiTextDirection: uiTextDirection,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: _PagePosterLayout.footerGap),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: _PagePosterLayout.footerPillSpacing,
                      runSpacing: _PagePosterLayout.footerPillRunSpacing,
                      children: [
                        const _PosterPill(
                          icon: Icons.auto_stories_rounded,
                          label: 'Shared from Tilawa',
                        ),
                        if (normalizedReciterName != null &&
                            normalizedReciterName.isNotEmpty)
                          _PosterPill(
                            icon: Icons.multitrack_audio_rounded,
                            label: normalizedReciterName,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterPill extends StatelessWidget {
  const _PosterPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: _PagePosterLayout.pillMaxWidth,
      ),
      child: Container(
        padding: _PagePosterLayout.pillPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_PagePosterLayout.pillRadius),
          color: AppPagePassagePosterColors.deepGreen.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: _PagePosterLayout.pillIconSize,
              color: AppPagePassagePosterColors.gold,
            ),
            const SizedBox(width: _PagePosterLayout.pillIconGap),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _PagePosterLayout.pillTextSize,
                  fontWeight: FontWeight.w600,
                  color: AppPagePassagePosterColors.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterOrb extends StatelessWidget {
  const _PosterOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _PagePosterLayout {
  static const double canvasWidth = 1080;
  static const double canvasHeight = 1350;
  static const double topOrbTop = -80;
  static const double topOrbRight = -40;
  static const double topOrbSize = 220;
  static const double bottomOrbBottom = -70;
  static const double bottomOrbLeft = -30;
  static const double bottomOrbSize = 180;
  static const EdgeInsets outerPadding = EdgeInsets.fromLTRB(54, 58, 54, 50);
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(42, 38, 42, 34);
  static const double contentRadius = 36;
  static const double headerGap = 24;
  static const double arabicTitleSize = 38;
  static const double arabicTitleHeight = 1.18;
  static const double subtitleGap = 8;
  static const double englishTitleSize = 18;
  static const double englishTitleLetterSpacing = 1.6;
  static const double readerGap = 22;
  static const double readerFramePadding = 20;
  static const double readerFrameRadius = 28;
  static const double readerClipRadius = 20;
  static const double footerGap = 18;
  static const double footerPillSpacing = 10;
  static const double footerPillRunSpacing = 10;
  static const double pillMaxWidth = 320;
  static const EdgeInsets pillPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const double pillRadius = 999;
  static const double pillIconSize = 16;
  static const double pillIconGap = 8;
  static const double pillTextSize = 16;
}
