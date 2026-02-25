/// Service interface for Surah-related operations.
///
/// Defines the contract for accessing surah metadata.
abstract class SurahService {
  /// Gets the surah name (default format).
  String getName(int surahNumber);

  /// Gets the surah name in English.
  String getNameEnglish(int surahNumber);

  /// Gets the surah name in Arabic.
  String getNameArabic(int surahNumber);

  /// Gets the place of revelation.
  String getPlaceOfRevelation(int surahNumber);

  /// Gets the total verse count in a surah.
  int getVerseCount(int surahNumber);

  /// Gets the English meaning of the surah name.
  String getEnglishName(int surahNumber);

  /// Gets the Turkish name of the surah.
  String getTurkishName(int surahNumber);

  /// Gets the detailed surah information.
  String getSurahInfo(int surahNumber);

  /// Gets the surah info from a specific book.
  String getSurahInfoFromBook(int surahNumber);

  /// Gets alternative names for the surah.
  String getSurahNames(int surahNumber);

  /// Gets surah names from a specific book.
  String getSurahNamesFromBook(int surahNumber);
}
