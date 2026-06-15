/// Service interface for Verse-related operations.
///
/// Defines the contract for accessing verse text and symbols.
abstract class VerseService {
  /// Gets the verse text in Arabic.
  String getVerse(int surahNumber, int verseNumber, {bool verseEndSymbol});

  /// Gets diacritic-stripped verse text for search and speech comparison.
  String getVerseNormal(int surahNumber, int verseNumber);

  /// Gets the verse text in QCF font format.
  String getVerseQCF(int surahNumber, int verseNumber, {bool verseEndSymbol});

  /// Gets the verse number in QCF font format (end symbol).
  String getVerseNumberQCF(int surahNumber, int verseNumber);

  /// Gets the verse end symbol.
  String getVerseEndSymbol(int verseNumber, {bool arabicNumeral});
}
