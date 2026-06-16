import '../../domain/repositories/verse_service.dart';
import '../../quran_exception.dart';
import '../sources/qcf_v4_data.dart';
import '../sources/quran_text.dart';

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

  static Map<String, Map<String, dynamic>>? _verseCache;

  /// Finds verse data from quran text.
  Map<String, dynamic>? _findVerse(int surahNumber, int verseNumber) {
    if (_verseCache == null) {
      _verseCache = {};
      for (final Map<String, dynamic> i in quranText) {
        final key = "${i['surah_number']}:${i['verse_number']}";
        _verseCache![key] = i;
      }
    }
    return _verseCache!['$surahNumber:$verseNumber'];
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
  String getVerseNormal(int surahNumber, int verseNumber) {
    final Map<String, dynamic>? verseData = _findVerse(
      surahNumber,
      verseNumber,
    );

    if (verseData == null) {
      throw const QuranException(
        'No verse found with given surahNumber and verseNumber.',
      );
    }

    return verseData['text_normal'] as String;
  }

  @override
  String getVerseQCF(
    int surahNumber,
    int verseNumber, {
    bool addSpace = true,
    bool verseEndSymbol = true,
  }) {
    final key = '$surahNumber:$verseNumber';
    String? qcfData = qcfV4Data[key];

    if (qcfData == null) {
      throw const QuranException(
        'No verse found with given surahNumber and verseNumber.',
      );
    }

    qcfData = _cleanQCFData(qcfData);

    if (!verseEndSymbol && qcfData.isNotEmpty) {
      // Remove the last character (which is the verse marker)
      qcfData = qcfData.substring(0, qcfData.length - 1);
    }

    if (addSpace) {
      final buffer = StringBuffer();
      final List<int> runes = qcfData.runes.toList();
      for (var i = 0; i < runes.length; i++) {
        if (i > 0) buffer.write(' ');
        buffer.writeCharCode(runes[i]);
      }
      qcfData = buffer.toString();
    }

    // QCF data stores word-glyphs as consecutive characters.
    return qcfData;
  }

  @override
  String getVerseNumberQCF(int surahNumber, int verseNumber) {
    final key = '$surahNumber:$verseNumber';
    final String? qcfDataRaw = qcfV4Data[key];

    if (qcfDataRaw == null) {
      throw const QuranException(
        'No verse found with given surahNumber and verseNumber.',
      );
    }

    final String cleaned = _cleanQCFData(qcfDataRaw);
    if (cleaned.isEmpty) {
      return '';
    }

    /// Ayah number is the last character in qcfData
    return cleaned.substring(cleaned.length - 1);
  }

  /// Cleans QCF data by removing all types of whitespace and trimming.
  String _cleanQCFData(String data) {
    return data.trim();
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
