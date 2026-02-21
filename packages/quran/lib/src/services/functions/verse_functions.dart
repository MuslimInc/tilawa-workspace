import '../quran_service_locator.dart';

/// Convenience functions for accessing Verse data.
///
/// These are top-level functions that delegate to [QuranServiceLocator]
/// for backward compatibility with existing code.

/// Takes [surahNumber], [verseNumber] & [verseEndSymbol] (optional) and
/// returns the Verse in Arabic.
///
/// Throws [QuranException] if verse is not found.
String getVerse(
  int surahNumber,
  int verseNumber, {
  bool verseEndSymbol = false,
}) => QuranServiceLocator.verseService.getVerse(
  surahNumber,
  verseNumber,
  verseEndSymbol: verseEndSymbol,
);

/// Takes [verseNumber], [arabicNumeral] (optional) and returns '۝' symbol
/// with verse number.
String getVerseEndSymbol(int verseNumber, {bool arabicNumeral = true}) =>
    QuranServiceLocator.verseService.getVerseEndSymbol(
      verseNumber,
      arabicNumeral: arabicNumeral,
    );

/// Gets the verse text in QCF font format.
///
/// Throws [QuranException] if verse is not found.
String getVerseQCF(
  int surahNumber,
  int verseNumber, {
  bool verseEndSymbol = true,
}) => QuranServiceLocator.verseService.getVerseQCF(
  surahNumber,
  verseNumber,
  verseEndSymbol: verseEndSymbol,
);

/// Gets the verse number in QCF font format (end symbol).
///
/// Throws [QuranException] if verse is not found.
String getVerseNumberQCF(int surahNumber, int verseNumber) =>
    QuranServiceLocator.verseService.getVerseNumberQCF(
      surahNumber,
      verseNumber,
    );
