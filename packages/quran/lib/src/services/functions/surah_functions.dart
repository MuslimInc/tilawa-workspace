import '../quran_service_locator.dart';

/// Convenience functions for accessing Surah metadata.
///
/// These are top-level functions that delegate to [QuranServiceLocator]
/// for backward compatibility with existing code.

/// Takes [surahNumber] and returns the Surah name.
///
/// Throws [QuranException] if surah number is invalid (not 1-114).
String getSurahName(int surahNumber) =>
    QuranServiceLocator.surahService.getName(surahNumber);

/// Takes [surahNumber] and returns the Surah name in English.
///
/// Throws [QuranException] if surah number is invalid.
String getSurahNameEnglish(int surahNumber) =>
    QuranServiceLocator.surahService.getNameEnglish(surahNumber);

/// Takes [surahNumber] and returns the Surah name in Arabic.
///
/// Throws [QuranException] if surah number is invalid.
String getSurahNameArabic(int surahNumber) =>
    QuranServiceLocator.surahService.getNameArabic(surahNumber);

/// Takes [surahNumber] and returns the place of revelation (Makkah/Madinah).
///
/// Throws [QuranException] if surah number is invalid.
String getPlaceOfRevelation(int surahNumber) =>
    QuranServiceLocator.surahService.getPlaceOfRevelation(surahNumber);

/// Takes [surahNumber] and returns the count of total verses in the Surah.
///
/// Throws [QuranException] if surah number is invalid.
int getVerseCount(int surahNumber) =>
    QuranServiceLocator.surahService.getVerseCount(surahNumber);
