import '../../../quran_qcf.dart';

/// Convenience functions for accessing Quran page data.
///
/// These are top-level functions that delegate to [QuranServiceLocator]
/// for backward compatibility with existing code.

/// Takes [pageNumber] and returns the page data.
///
/// Throws [QuranException] if page number is invalid (not 1-604).
List<Map<String, int>> getPageData(int pageNumber) =>
    QuranServiceLocator.quranDataService.getPageData(pageNumber);

/// Takes [pageNumber] and returns total surahs count in that page.
///
/// Throws [QuranException] if page number is invalid.
int getSurahCountByPage(int pageNumber) =>
    QuranServiceLocator.quranDataService.getSurahCountByPage(pageNumber);

/// Takes [pageNumber] and returns total verses count in that page.
///
/// Throws [QuranException] if page number is invalid.
int getVerseCountByPage(int pageNumber) =>
    QuranServiceLocator.quranDataService.getVerseCountByPage(pageNumber);

/// Takes [surahNumber] & [verseNumber] and returns Juz number.
///
/// Returns -1 if no matching juz is found.
int getJuzNumber(int surahNumber, int verseNumber) =>
    QuranServiceLocator.quranDataService.getJuzNumber(surahNumber, verseNumber);

/// Takes [surahNumber], [verseNumber] and returns the quarter number (1-240).
int getQuarterNumber(int surahNumber, int verseNumber) => QuranServiceLocator
    .quranDataService
    .getQuarterNumber(surahNumber, verseNumber);

/// Takes [surahNumber], [verseNumber] and returns the page number.
///
/// Throws [QuranException] if surah or verse number is invalid.
int getPageNumber(int surahNumber, int verseNumber) => QuranServiceLocator
    .quranDataService
    .getPageNumber(surahNumber, verseNumber);
