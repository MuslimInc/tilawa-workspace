/// Centralized language configuration for the app
class LanguageConfig {
  // Private constructor to prevent instantiation
  LanguageConfig._();

  /// Default language code for the app
  static const String defaultLanguageCode = 'ar';

  /// Default locale for the app
  static const String defaultLocale = 'ar';

  /// Supported language codes in order of preference
  static const List<String> supportedLanguageCodes = ['ar', 'en'];

  /// Language key for final SharedPreferencesAsync _prefs
  static const String languageKey = 'selected_language';

  /// Convert app language code to API language code
  static String convertToApiLanguageCode(String? languageCode) {
    return switch (languageCode) {
      'en' => 'eng',
      'ar' => 'ar',
      _ => defaultLanguageCode,
    };
  }

  /// Get the default language code
  static String getDefaultLanguageCode() => defaultLanguageCode;

  /// Get supported language codes
  static List<String> getSupportedLanguageCodes() => supportedLanguageCodes;
}
