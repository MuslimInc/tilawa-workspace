import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A Quran-focused 9:16 canvas used for reel generation.
class ReelContentRenderer extends StatelessWidget {
  const ReelContentRenderer({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    this.showBasmalah = true,
    this.reciterName,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final bool showBasmalah;
  final String? reciterName;

  String get _arabicSurahName => getSurahNameArabic(surahNumber);
  String get _englishSurahName => getSurahNameEnglish(surahNumber);

  String get _ayahRangeLabel =>
      fromAyah == toAyah ? 'آية $fromAyah' : 'الآيات $fromAyah - $toAyah';

  @override
  Widget build(BuildContext context) {
    final normalizedReciterName = reciterName?.trim();

    return SizedBox(
      width: 1080,
      height: 1920,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _ReelPalette.deepGreen,
              _ReelPalette.forestGreen,
              _ReelPalette.tealGreen,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -140,
              right: -60,
              child: TilawaAmbientOrb(
                size: 320,
                color: _ReelPalette.mint,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: -120,
              left: -50,
              child: TilawaAmbientOrb(
                size: 260,
                color: _ReelPalette.gold,
                opacity: 0.12,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: _ReelPalette.gold.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 96, 72, 88),
              child: Column(
                children: [
                  const _BrandSeal(),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(56, 56, 56, 48),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(
                          color: _ReelPalette.gold.withValues(alpha: 0.58),
                          width: 2,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _ReelPalette.parchment,
                            _ReelPalette.warmParchment,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SurahHero(
                            arabicSurahName: _arabicSurahName,
                            englishSurahName: _englishSurahName,
                            surahNumber: surahNumber,
                            ayahRangeLabel: _ayahRangeLabel,
                            reciterName: normalizedReciterName,
                          ),
                          if (showBasmalah &&
                              surahNumber != 1 &&
                              surahNumber != 9 &&
                              fromAyah == 1) ...[
                            const SizedBox(height: 36),
                            _Basmalah(
                              pageNumber: getPageNumber(surahNumber, fromAyah),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                34,
                                40,
                                34,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                color: Colors.white.withValues(alpha: 0.42),
                                border: Border.all(
                                  color: _ReelPalette.gold.withValues(
                                    alpha: 0.26,
                                  ),
                                ),
                              ),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: _AyahFlow(
                                  surahNumber: surahNumber,
                                  fromAyah: fromAyah,
                                  toAyah: toAyah,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _ReelFooter(reciterName: normalizedReciterName),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandSeal extends StatelessWidget {
  const _BrandSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ReelPalette.gold.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: _ReelPalette.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tilawa',
            style: GoogleFonts.alexandria(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _ReelPalette.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahHero extends StatelessWidget {
  const _SurahHero({
    required this.arabicSurahName,
    required this.englishSurahName,
    required this.surahNumber,
    required this.ayahRangeLabel,
    required this.reciterName,
  });

  final String arabicSurahName;
  final String englishSurahName;
  final int surahNumber;
  final String ayahRangeLabel;
  final String? reciterName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(color: _ReelPalette.gold.withValues(alpha: 0.36)),
      ),
      child: Column(
        children: [
          Text(
            String.fromCharCode(0xF100 + surahNumber - 1),
            style: const TextStyle(
              fontFamily: 'QCF_BSML',
              package: 'quran',
              fontSize: 78,
              color: _ReelPalette.deepGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            arabicSurahName,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 46,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: _ReelPalette.deepGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            englishSurahName.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.alexandria(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: _ReelPalette.deepGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.format_list_numbered_rounded,
                label: ayahRangeLabel,
              ),
              if (reciterName != null && reciterName!.isNotEmpty)
                _HeroPill(
                  icon: Icons.multitrack_audio_rounded,
                  label: reciterName!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

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
          color: _ReelPalette.deepGreen.withValues(alpha: 0.08),
          border: Border.all(
            color: _ReelPalette.deepGreen.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _ReelPalette.gold),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ReelPalette.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahFlow extends StatelessWidget {
  const _AyahFlow({
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;

  _AyahTypography _resolveTypography() {
    final verseCount = toAyah - fromAyah + 1;
    var glyphCount = 0;

    for (int ayah = fromAyah; ayah <= toAyah; ayah++) {
      glyphCount += getVerseQCF(
        surahNumber,
        ayah,
        verseEndSymbol: false,
      ).length;
    }

    if (verseCount >= 24 || glyphCount > 600) {
      return const _AyahTypography(
        fontSize: 48,
        lineHeight: 1.92,
        endSymbolHeight: 1.52,
      );
    }

    if (verseCount >= 18 || glyphCount > 440) {
      return const _AyahTypography(
        fontSize: 54,
        lineHeight: 2.0,
        endSymbolHeight: 1.6,
      );
    }

    if (verseCount >= 12 || glyphCount > 300) {
      return const _AyahTypography(
        fontSize: 62,
        lineHeight: 2.12,
        endSymbolHeight: 1.68,
      );
    }

    if (verseCount >= 8 || glyphCount > 180) {
      return const _AyahTypography(
        fontSize: 68,
        lineHeight: 2.2,
        endSymbolHeight: 1.74,
      );
    }

    return const _AyahTypography(
      fontSize: 74,
      lineHeight: 2.28,
      endSymbolHeight: 1.82,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = _resolveTypography();
    final spans = <InlineSpan>[];

    for (int ayah = fromAyah; ayah <= toAyah; ayah++) {
      final pageNumber = getPageNumber(surahNumber, ayah);
      final pageFont = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';
      final baseStyle = TextStyle(
        fontFamily: pageFont,
        fontSize: typography.fontSize,
        height: typography.lineHeight,
        color: _ReelPalette.ink.withValues(alpha: 0.94),
      );

      spans.add(
        TextSpan(
          text: getVerseQCF(surahNumber, ayah, verseEndSymbol: false),
          style: baseStyle,
        ),
      );

      spans.add(
        TextSpan(
          text: '${getVerseNumberQCF(surahNumber, ayah)} ',
          style: baseStyle.copyWith(height: typography.endSymbolHeight),
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

class _AyahTypography {
  const _AyahTypography({
    required this.fontSize,
    required this.lineHeight,
    required this.endSymbolHeight,
  });

  final double fontSize;
  final double lineHeight;
  final double endSymbolHeight;
}

class _ReelFooter extends StatelessWidget {
  const _ReelFooter({required this.reciterName});

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
          color: _ReelPalette.deepGreen.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _ReelPalette.gold),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _ReelPalette.deepGreen.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Basmalah extends StatelessWidget {
  const _Basmalah({required this.pageNumber});

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
        fontSize: 86,
        height: 1.28,
        color: _ReelPalette.deepGreen,
      ),
    );
  }
}

abstract final class _ReelPalette {
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
