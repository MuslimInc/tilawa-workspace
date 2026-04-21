import '../data/quran_text.dart';
import 'interfaces/search_service.dart';

/// Implementation of [SearchService] using local data sources.
///
/// Follows Single Responsibility Principle - only handles search operations.
class SearchServiceImpl implements SearchService {
  const SearchServiceImpl();

  /// Maximum number of search results to return.
  static const int _maxResults = 50;

  @override
  Map<String, dynamic> searchWords(String words) {
    final List<Map<String, int>> result = [];
    final String lowercaseWords = words.toLowerCase();

    // First, search in normalized text
    for (final Map<String, dynamic> i in quranText) {
      if (result.length >= _maxResults) {
        break;
      }

      if ((i['text_normal'] as String).toLowerCase().contains(lowercaseWords)) {
        result.add({
          'suraNumber': i['surah_number'] as int,
          'verseNumber': i['verse_number'] as int,
        });
      }
    }

    // If no results, search in content
    if (result.isEmpty) {
      for (final Map<String, dynamic> i in quranText) {
        if (result.length >= _maxResults) {
          break;
        }

        if ((i['content'] as String).toLowerCase().contains(lowercaseWords)) {
          result.add({
            'suraNumber': i['surah_number'] as int,
            'verseNumber': i['verse_number'] as int,
          });
        }
      }
    }

    return {'occurences': result.length, 'result': result};
  }
}
