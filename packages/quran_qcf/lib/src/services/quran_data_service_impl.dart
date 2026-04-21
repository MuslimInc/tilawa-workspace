import '../data/juzs.dart';
import '../data/page_data.dart';
import '../data/quarters.dart';
import '../quran_exception.dart';
import 'interfaces/quran_data_service.dart';

/// Implementation of [QuranDataService] using local data sources.
///
/// Follows Single Responsibility Principle - only handles Quran page/juz data.
class QuranDataServiceImpl implements QuranDataService {
  const QuranDataServiceImpl();

  /// Validates page number is in valid range (1-604).
  void _validatePageNumber(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw const QuranException(
        'Invalid page number. Page number must be between 1 and 604',
      );
    }
  }

  @override
  List<Map<String, int>> getPageData(int pageNumber) {
    _validatePageNumber(pageNumber);
    return pageData[pageNumber - 1];
  }

  @override
  int getSurahCountByPage(int pageNumber) {
    _validatePageNumber(pageNumber);
    return pageData[pageNumber - 1].length;
  }

  @override
  int getVerseCountByPage(int pageNumber) {
    _validatePageNumber(pageNumber);
    var totalVerseCount = 0;
    for (var i = 0; i < pageData[pageNumber - 1].length; i++) {
      totalVerseCount += pageData[pageNumber - 1][i]['end']!;
    }
    return totalVerseCount;
  }

  @override
  int getJuzNumber(int surahNumber, int verseNumber) {
    for (final Map<String, dynamic> j in juzData) {
      final verses = j['verses'] as Map<dynamic, dynamic>;
      if (verses.containsKey(surahNumber)) {
        final range = verses[surahNumber] as List;
        if (verseNumber >= range[0] && verseNumber <= range[1]) {
          return j['id'] as int;
        }
      }
    }
    return -1;
  }

  @override
  int getQuarterNumber(int surahNumber, int verseNumber) {
    // Search quarters backwards to find the current active quarter
    for (int i = quartersData.length - 1; i >= 0; i--) {
      final Map<String, int> q = quartersData[i];
      if (surahNumber > q['surah']! ||
          (surahNumber == q['surah']! && verseNumber >= q['ayah']!)) {
        return i + 1;
      }
    }
    return 1;
  }

  static Map<String, int>? _pageLookupCache;

  @override
  int getPageNumber(int surahNumber, int verseNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw const QuranException('No Surah found with given surahNumber');
    }

    if (_pageLookupCache == null) {
      _pageLookupCache = {};
      for (var pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
        for (final Map<String, int> entry in pageData[pageIndex]) {
          final int surah = entry['surah']!;
          final int start = entry['start']!;
          final int end = entry['end']!;
          for (var v = start; v <= end; v++) {
            _pageLookupCache!['$surah:$v'] = pageIndex + 1;
          }
        }
      }
    }

    final int? page = _pageLookupCache!['$surahNumber:$verseNumber'];
    if (page == null) {
      throw const QuranException('Invalid verse number.');
    }
    return page;
  }
}
