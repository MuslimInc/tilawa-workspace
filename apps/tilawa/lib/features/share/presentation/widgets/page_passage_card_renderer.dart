import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      width: 1080,
      height: 1350,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _PagePosterPalette.deepGreen,
              _PagePosterPalette.forestGreen,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -40,
              child: _PosterOrb(
                size: 220,
                color: _PagePosterPalette.mint,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: -70,
              left: -30,
              child: _PosterOrb(
                size: 180,
                color: _PagePosterPalette.gold,
                opacity: 0.12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 58, 54, 50),
              child: Container(
                padding: const EdgeInsets.fromLTRB(42, 38, 42, 34),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: _PagePosterPalette.gold.withValues(alpha: 0.42),
                    width: 2,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _PagePosterPalette.parchment,
                      _PagePosterPalette.warmParchment,
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
                    const SizedBox(height: 24),
                    Text(
                      arabicSurahNames,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 38,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                        color: _PagePosterPalette.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      englishSurahNames.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                        fontSize: 18,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                        color: _PagePosterPalette.deepGreen.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withValues(alpha: 0.42),
                          border: Border.all(
                            color: _PagePosterPalette.gold.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: ReaderPageContentRenderer(
                            pageNumber: pageNumber,
                            uiTextDirection: uiTextDirection,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
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
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: _PagePosterPalette.deepGreen.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _PagePosterPalette.gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _PagePosterPalette.deepGreen,
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

abstract final class _PagePosterPalette {
  static const Color deepGreen = Color(0xFF0B342E);
  static const Color forestGreen = Color(0xFF145247);
  static const Color gold = Color(0xFFE1C17B);
  static const Color mint = Color(0xFF8FDFC0);
  static const Color parchment = Color(0xFFF7F1E1);
  static const Color warmParchment = Color(0xFFEFE1C2);
}
