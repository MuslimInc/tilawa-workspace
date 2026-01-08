/// Utility class for Arabic text processing.
///
/// Provides methods for normalizing Arabic text to enable
/// consistent searching and comparison.
class ArabicTextUtils {
  const ArabicTextUtils._();

  /// Normalizes Arabic text by removing diacritics and unifying character forms.
  ///
  /// This method:
  /// - Removes diacritics (Tashkeel): Fatha, Damma, Kasra, Sukun, Shadda, Tanwin
  /// - Removes Quranic specific marks: superscript Alef, etc.
  /// - Normalizes Alef forms: أ, إ, آ, ٱ → ا
  /// - Normalizes Alef Maqsura: ى → ي
  /// - Normalizes Ta Marbuta: ة → ه
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var normalized = text;

    // Remove diacritics (Tashkeel)
    // Range includes Fatha, Damma, Kasra, Sukun, Shadda, Tanwin, etc.
    // Also removes Quranic specific marks like superscript Alef
    normalized = normalized.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'),
      '',
    );

    // Normalize Alef forms (أ, إ, آ, ٱ -> ا)
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // Normalize Ya/Alef Maqsura (ى -> ي)
    normalized = normalized.replaceAll('ى', 'ي');

    // Normalize Ta Marbuta (ة -> ه)
    normalized = normalized.replaceAll('ة', 'ه');

    return normalized;
  }

  /// Checks if the text contains Arabic characters.
  static bool containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Removes all non-Arabic characters from the text.
  static String extractArabicOnly(String text) {
    return text.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '');
  }
}
