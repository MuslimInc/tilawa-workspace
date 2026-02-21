/// Quran-related constants.
///
/// Contains static values for Quran structure such as page count,
/// surah count, verse count, etc.
class QuranConstants {
  QuranConstants._();

  /// The most standard and common copy of Arabic only Quran total pages count.
  static const int totalPagesCount = 604;

  /// The constant total of Makki surahs.
  static const int totalMakkiSurahs = 89;

  /// The constant total of Madani surahs.
  static const int totalMadaniSurahs = 25;

  /// The constant total juz count.
  static const int totalJuzCount = 30;

  /// The constant total surah count.
  static const int totalSurahCount = 114;

  /// The constant total verse count.
  static const int totalVerseCount = 6236;

  /// Minimum valid page number.
  static const int minPageNumber = 1;

  /// Maximum valid page number.
  static const int maxPageNumber = 604;

  /// Minimum valid surah number.
  static const int minSurahNumber = 1;

  /// Maximum valid surah number.
  static const int maxSurahNumber = 114;
}
