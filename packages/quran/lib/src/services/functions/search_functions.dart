import '../quran_service_locator.dart';

/// Convenience functions for searching and text processing.
///
/// These are top-level functions that delegate to [QuranServiceLocator]
/// for backward compatibility with existing code.

/// Searches for [words] in the Quran text.
///
/// Returns a map with 'occurences' count and 'result' list of matching verses.
/// Results are limited to 50 matches.
Map<String, dynamic> searchWords(String words) =>
    QuranServiceLocator.searchService.searchWords(words);

/// Normalizes Arabic text for search/comparison.
///
/// Removes Koranic annotations, tatweel, tashkeel, and unifies certain letters.
String normalise(String input) =>
    QuranServiceLocator.textNormalizationService.normalise(input);

/// Removes Arabic diacritics (tashkeel) from the input text.
///
/// Keeps base letters and removes Fatha, Damma, Kasra, Shadda and tanwin marks.
String removeDiacritics(String input) =>
    QuranServiceLocator.textNormalizationService.removeDiacritics(input);
