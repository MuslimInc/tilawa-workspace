import 'package:tilawa/core/utils/arabic_search_normalizer.dart';

/// Normalizes reciter search input for forgiving Arabic and Latin matching.
abstract final class ReciterSearchQueryNormalizer {
  static String normalize(String input) =>
      ArabicSearchNormalizer.normalize(input);

  static bool matches({
    required String query,
    required String reciterName,
    required String reciterLetter,
  }) {
    final String normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final String name = normalize(reciterName);
    final String letter = normalize(reciterLetter);
    return name.contains(normalizedQuery) || letter.contains(normalizedQuery);
  }
}
