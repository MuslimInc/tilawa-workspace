/// Service interface for Quran page and juz data operations.
///
/// Defines the contract for accessing Quran page data, juz information, etc.
abstract class QuranDataService {
  /// Gets page data for a given page number.
  List<Map<String, int>> getPageData(int pageNumber);

  /// Gets the count of surahs on a page.
  int getSurahCountByPage(int pageNumber);

  /// Gets the count of verses on a page.
  int getVerseCountByPage(int pageNumber);

  /// Gets the Juz number for a surah and verse.
  int getJuzNumber(int surahNumber, int verseNumber);

  /// Gets the quarter number for a surah and verse (1-240).
  int getQuarterNumber(int surahNumber, int verseNumber);

  /// Gets the page number for a surah and verse.
  int getPageNumber(int surahNumber, int verseNumber);
}
