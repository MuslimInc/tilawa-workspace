const arabicLanguageCode = 'ar';
const englishLanguageCode = 'en';

/// Display emoji for Arabic in language pickers.
const arabicLanguageEmoji = '🇪🇬';

/// Display emoji for English in language pickers.
const englishLanguageEmoji = '🇺🇸';

/// API language codes
const _arabicApiLanguageCode = 'ar';
const _englishApiLanguageCode = 'eng';

/// Centralized language configuration for the app
class LanguageConfig {
  // Private constructor to prevent instantiation
  LanguageConfig._();

  /// Default language code for the app (first launch and fallbacks).
  static const String defaultLanguageCode = arabicLanguageCode;

  /// Supported language codes in order of preference
  static const List<String> supportedLanguageCodes = [
    arabicLanguageCode,
    englishLanguageCode,
  ];

  /// Language key for final SharedPreferencesAsync _prefs
  static const String languageKey = 'selected_language';

  /// Convert app language code to API language code
  static String convertToApiLanguageCode(String? languageCode) {
    return switch (languageCode) {
      englishLanguageCode => _englishApiLanguageCode,
      arabicLanguageCode => _arabicApiLanguageCode,
      _ => _arabicApiLanguageCode,
    };
  }

  /// Normalizes app locale to `ar` | `en` for Firebase push copy.
  static String normalizeForPushNotifications(String languageCode) {
    return languageCode == arabicLanguageCode
        ? arabicLanguageCode
        : englishLanguageCode;
  }

  /// Get supported language codes
  static List<String> getSupportedLanguageCodes() => supportedLanguageCodes;

  /// Returns the display emoji for a supported app [languageCode].
  static String emojiForLanguageCode(String languageCode) {
    return switch (languageCode) {
      arabicLanguageCode => arabicLanguageEmoji,
      englishLanguageCode => englishLanguageEmoji,
      _ => '',
    };
  }
}
