import '../../domain/models/search_models.dart';
import '../../domain/repositories/search_service.dart';
import '../sources/quran_text.dart';

/// Implementation of [SearchService] using local data sources.
///
/// Follows Single Responsibility Principle - only handles search operations.
class SearchServiceImpl implements SearchService {
  const SearchServiceImpl();

  /// Maximum number of search results to return.
  static const int _maxResults = 50;

  @override
  SearchResult searchWords(String words) {
    if (words.isEmpty) {
      return const SearchResult(occurrences: 0, entries: []);
    }

    final List<SearchEntry> results = [];
    final String query = words.toLowerCase();

    // First, search in normalized text
    for (final Map<String, dynamic> verse in quranText) {
      if (results.length >= _maxResults) break;

      final String normalText = (verse['text_normal'] as String).toLowerCase();
      if (normalText.contains(query)) {
        results.add(
          SearchEntry(
            surahNumber: verse['surah_number'] as int,
            verseNumber: verse['verse_number'] as int,
          ),
        );
      }
    }

    // If no results, search in content (original text with diacritics)
    if (results.isEmpty) {
      for (final Map<String, dynamic> verse in quranText) {
        if (results.length >= _maxResults) break;

        final String content = (verse['content'] as String).toLowerCase();
        if (content.contains(query)) {
          results.add(
            SearchEntry(
              surahNumber: verse['surah_number'] as int,
              verseNumber: verse['verse_number'] as int,
            ),
          );
        }
      }
    }

    return SearchResult(occurrences: results.length, entries: results);
  }
}
