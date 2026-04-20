import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';

import '../utils/share_ayah_range_utils.dart';

/// A premium static poster used for screenshot previews and audio artwork.
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

  String get _arabicSurahName => getSurahNameArabic(surahNumber);
  String get _englishSurahName => getSurahNameEnglish(surahNumber);

  @override
  Widget build(BuildContext context) {
    final normalizedReciterName = reciterName?.trim();
    final ayahRange = normalizeShareAyahRange(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );

    return Column(
      children: [
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _PosterAyahFlow(
              surahNumber: surahNumber,
              fromAyah: ayahRange.fromAyah,
              toAyah: ayahRange.toAyah,
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
    );
  }
}

class _PosterAyahFlow extends StatelessWidget {
  const _PosterAyahFlow({
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;

  _PosterTypography _resolveTypography() {
    final ayahRange = normalizeShareAyahRange(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
    final verseCount = ayahRange.toAyah - ayahRange.fromAyah + 1;
    var glyphCount = 0;

    for (int ayah = ayahRange.fromAyah; ayah <= ayahRange.toAyah; ayah++) {
      glyphCount +=
          tryGetVerseQcfText(
            surahNumber,
            ayah,
            verseEndSymbol: false,
          )?.length ??
          getVerse(surahNumber, ayah, verseEndSymbol: false).length;
    }

    if (verseCount >= 16 || glyphCount > 460) {
      return const _PosterTypography(44, 1.9, 1.46);
    }
    if (verseCount >= 10 || glyphCount > 280) {
      return const _PosterTypography(50, 2.0, 1.54);
    }
    if (verseCount >= 6 || glyphCount > 160) {
      return const _PosterTypography(56, 2.1, 1.62);
    }
    return const _PosterTypography(64, 2.2, 1.72);
  }

  @override
  Widget build(BuildContext context) {
    final ayahRange = normalizeShareAyahRange(
      surahNumber: surahNumber,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
    final typography = _resolveTypography();
    final spans = <InlineSpan>[];

    for (int ayah = ayahRange.fromAyah; ayah <= ayahRange.toAyah; ayah++) {
      final pageNumber = getPageNumber(surahNumber, ayah);
      final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
      final qcfStyle = TextStyle(
        fontFamily: pageFont,
        fontSize: typography.fontSize,
        height: typography.lineHeight,
        color: _PosterPalette.ink.withValues(alpha: 0.92),
      );
      final fallbackStyle = GoogleFonts.amiri(
        fontSize: typography.fontSize * 0.76,
        height: typography.lineHeight,
        color: _PosterPalette.ink.withValues(alpha: 0.92),
      );
      final verseText =
          tryGetVerseQcfText(surahNumber, ayah, verseEndSymbol: false) ??
          getVerse(surahNumber, ayah, verseEndSymbol: false);
      final verseNumberText =
          tryGetVerseNumberQcfText(surahNumber, ayah) ??
          getVerseEndSymbol(ayah);
      final usesQcf =
          tryGetVerseQcfText(surahNumber, ayah, verseEndSymbol: false) != null;
      final baseStyle = usesQcf ? qcfStyle : fallbackStyle;

      spans.add(TextSpan(text: verseText, style: baseStyle));
      spans.add(
        TextSpan(
          text: '$verseNumberText ',
          style: baseStyle.copyWith(height: typography.endSymbolHeight),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RichText(
          text: TextSpan(children: spans),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        );
      },
    );
  }
}

class _PosterTypography {
  const _PosterTypography(this.fontSize, this.lineHeight, this.endSymbolHeight);

  final double fontSize;
  final double lineHeight;
  final double endSymbolHeight;
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
          color: _PosterPalette.deepGreen.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _PosterPalette.gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _PosterPalette.deepGreen,
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

abstract final class _PosterPalette {
  static const Color deepGreen = Color(0xFF0B342E);
  static const Color forestGreen = Color(0xFF145247);
  static const Color gold = Color(0xFFE1C17B);
  static const Color mint = Color(0xFF8FDFC0);
  static const Color parchment = Color(0xFFF7F1E1);
  static const Color warmParchment = Color(0xFFEFE1C2);
  static const Color ink = Color(0xFF1E1B16);
}
