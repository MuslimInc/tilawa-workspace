import '../../core/constants/quran_constants.dart';
import '../../core/constants/surah_header_banner_constants.dart';

/// Contract for resolving a Surah number to its QCF header glyph.
abstract class SurahHeaderGlyphProvider {
  const SurahHeaderGlyphProvider();

  String glyphForSurah(int surahNumber);
}

/// QCF_BSML glyph provider backed by an indexed lookup table.
class QcfSurahHeaderGlyphProvider implements SurahHeaderGlyphProvider {
  const QcfSurahHeaderGlyphProvider();

  static final List<String> _glyphs = List<String>.unmodifiable(
    List<String>.generate(QuranConstants.totalSurahCount, (int index) {
      return String.fromCharCode(
        SurahHeaderBannerConstants.glyphBaseCodePoint + index,
      );
    }, growable: false),
  );

  @override
  String glyphForSurah(int surahNumber) {
    if (surahNumber < QuranConstants.minSurahNumber ||
        surahNumber > QuranConstants.maxSurahNumber) {
      throw RangeError.range(
        surahNumber,
        QuranConstants.minSurahNumber,
        QuranConstants.maxSurahNumber,
        'surahNumber',
      );
    }
    return _glyphs[surahNumber - QuranConstants.minSurahNumber];
  }
}
