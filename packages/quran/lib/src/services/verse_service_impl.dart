import '../data/quran_text.dart';
import '../quran_exception.dart';
import 'interfaces/verse_service.dart';

/// Implementation of [VerseService] using local data sources.
///
/// Follows Single Responsibility Principle - only handles verse text operations.
class VerseServiceImpl implements VerseService {
  const VerseServiceImpl();

  /// Arabic number mapping for verse end symbols.
  static const Map<String, String> _arabicNumbers = {
    '0': '٠',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };

  /// Finds verse data from quran text.
  Map<String, dynamic>? _findVerse(int surahNumber, int verseNumber) {
    for (final Map<String, dynamic> i in quranText) {
      if (i['surah_number'] == surahNumber &&
          i['verse_number'] == verseNumber) {
        return i;
      }
    }
    return null;
  }

  @override
  String getVerse(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  }) {
    final Map<String, dynamic>? verseData = _findVerse(
      surahNumber,
      verseNumber,
    );

    if (verseData == null) {
      throw const QuranException(
        'No verse found with given surahNumber and verseNumber.',
      );
    }

    final verse = verseData['content'] as String;
    return verse + (verseEndSymbol ? getVerseEndSymbol(verseNumber) : '');
  }

  @override
  String getVerseQCF(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = true,
  }) {
    final Map<String, dynamic>? verseData = _findVerse(
      surahNumber,
      verseNumber,
    );

    if (verseData == null) {
      throw const QuranException(
        'No verse found with given surahNumber and verseNumber.',
      );
    }

    final qcfData = verseData['qcfData'] as String;
    return verseEndSymbol ? qcfData : qcfData.substring(0, qcfData.length - 1);
  }

  @override
  String getVerseNumberQCF(int surahNumber, int verseNumber) {
    final Map<String, dynamic>? verseData = _findVerse(
      surahNumber,
      verseNumber,
    );

    if (verseData == null) {
      throw const QuranException(
        'No verse found with given surahNumber and verseNumber.',
      );
    }

    final qcfData = verseData['qcfData'] as String;
    return qcfData.substring(qcfData.length - 1);
  }

  @override
  String getVerseEndSymbol(int verseNumber, {bool arabicNumeral = true}) {
    if (!arabicNumeral) {
      return '\u06dd$verseNumber';
    }

    final List<String> digits = verseNumber.toString().split('');
    final buffer = StringBuffer();

    for (final e in digits) {
      buffer.write(_arabicNumbers[e]);
    }

    return '\u06dd$buffer';
  }
}
