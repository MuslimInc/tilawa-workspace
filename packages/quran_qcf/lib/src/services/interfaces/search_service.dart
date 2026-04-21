/// Service interface for text search operations.
///
/// Defines the contract for searching within Quran text.
abstract class SearchService {
  /// Searches for words in the Quran text.
  Map<String, dynamic> searchWords(String words);
}
