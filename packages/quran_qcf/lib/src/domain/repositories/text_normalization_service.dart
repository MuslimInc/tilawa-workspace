/// Service interface for text normalization operations.
///
/// Defines the contract for normalizing and processing Arabic text.
abstract class TextNormalizationService {
  /// Normalizes Arabic text for search/comparison.
  String normalise(String input);

  /// Removes Arabic diacritics from text.
  String removeDiacritics(String input);
}
