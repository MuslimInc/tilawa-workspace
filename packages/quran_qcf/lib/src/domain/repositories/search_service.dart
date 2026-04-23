import '../models/search_models.dart';

/// Service interface for text search operations.
///
/// Defines the contract for searching within Quran text.
abstract class SearchService {
  /// Searches for words in the Quran text.
  SearchResult searchWords(String words);
}
