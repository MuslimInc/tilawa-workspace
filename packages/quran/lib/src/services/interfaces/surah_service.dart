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
}
