import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';

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

    return SizedBox(
      width: 1080,
      height: 1350,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_PosterPalette.deepGreen, _PosterPalette.forestGreen],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -40,
              child: _PosterOrb(
                size: 220,
                color: _PosterPalette.mint,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: -70,
              left: -30,
              child: _PosterOrb(
                size: 180,
                color: _PosterPalette.gold,
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
                    color: _PosterPalette.gold.withValues(alpha: 0.42),
                    width: 2,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _PosterPalette.parchment,
                      _PosterPalette.warmParchment,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _PosterPill(
                          icon: Icons.auto_stories_rounded,
                          label: 'Tilawa',
                        ),
                        const Spacer(),
                        _PosterPill(
                          icon: Icons.menu_book_rounded,
                          label: fromAyah == toAyah
                              ? 'آية $fromAyah'
                              : 'الآيات $fromAyah - $toAyah',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _arabicSurahName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 42,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: _PosterPalette.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _englishSurahName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                        fontSize: 20,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                        color: _PosterPalette.deepGreen.withValues(alpha: 0.72),
                      ),
                    ),
                    if (surahNumber != 1 &&
                        surahNumber != 9 &&
                        fromAyah == 1) ...[
                      const SizedBox(height: 24),
                      _PosterBasmalah(
                        pageNumber: getPageNumber(surahNumber, fromAyah),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withValues(alpha: 0.42),
                          border: Border.all(
                            color: _PosterPalette.gold.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: _PosterAyahFlow(
                            surahNumber: surahNumber,
                            fromAyah: fromAyah,
                            toAyah: toAyah,
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
    final verseCount = toAyah - fromAyah + 1;
    var glyphCount = 0;

    for (int ayah = fromAyah; ayah <= toAyah; ayah++) {
      glyphCount += getVerseQCF(
        surahNumber,
        ayah,
        verseEndSymbol: false,
      ).length;
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
    final typography = _resolveTypography();
    final spans = <InlineSpan>[];

    for (int ayah = fromAyah; ayah <= toAyah; ayah++) {
      final pageNumber = getPageNumber(surahNumber, ayah);
      final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
      final style = TextStyle(
        fontFamily: pageFont,
        fontSize: typography.fontSize,
        height: typography.lineHeight,
        color: _PosterPalette.ink.withValues(alpha: 0.92),
      );

      spans.add(
        TextSpan(
          text: getVerseQCF(surahNumber, ayah, verseEndSymbol: false),
          style: style,
        ),
      );
      spans.add(
        TextSpan(
          text: '${getVerseNumberQCF(surahNumber, ayah)} ',
          style: style.copyWith(height: typography.endSymbolHeight),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              child: RichText(
                text: TextSpan(children: spans),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
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

class _PosterBasmalah extends StatelessWidget {
  const _PosterBasmalah({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final String bismillahText;
    final String bismillahFont;
    final String? package;

    if (pageNumber == 1) {
      bismillahText = '\uFC41\uFC42\uFC43\uFC44';
      bismillahFont = 'QCF_P001';
      package = null;
    } else {
      bismillahText = '齃𧻓𥳐龎';
      bismillahFont = 'QCF_BSML';
      package = 'quran';
    }

    return Text(
      bismillahText,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: bismillahFont,
        package: package,
        fontSize: 70,
        height: 1.2,
        color: _PosterPalette.deepGreen,
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
