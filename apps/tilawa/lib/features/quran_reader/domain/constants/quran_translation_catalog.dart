/// Bundled Quran translation metadata for attribution in the reader UI.
abstract final class QuranTranslationCatalog {
  static const String qulSourceName = 'Quranic Universal Library';

  static String translationName(String languageCode) {
    return switch (languageCode) {
      'en' => 'Saheeh International',
      _ => '',
    };
  }

  static String? qulResourceUrl(String languageCode) {
    return switch (languageCode) {
      'en' => 'https://qul.tarteel.ai/resources/translation/193',
      _ => null,
    };
  }

  static bool hasBundledTranslation(String languageCode) =>
      translationName(languageCode).isNotEmpty;
}
