import '../data/juzs.dart';
import '../data/page_data.dart';
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
  int getPageNumber(int surahNumber, int verseNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw const QuranException('No Surah found with given surahNumber');
    }

    for (var pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
      for (
        var surahIndexInPage = 0;
        surahIndexInPage < pageData[pageIndex].length;
        surahIndexInPage++
      ) {
        final Map<String, int> e = pageData[pageIndex][surahIndexInPage];
        if (e['surah'] == surahNumber &&
            e['start']! <= verseNumber &&
            e['end']! >= verseNumber) {
          return pageIndex + 1;
        }
      }
    }

    throw const QuranException('Invalid verse number.');
  }
}
