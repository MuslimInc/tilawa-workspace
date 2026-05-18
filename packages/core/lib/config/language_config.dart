import 'dart:ui';

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

  /// Default language code for the app
  static String get defaultLanguageCode {
    final String deviceLocal = PlatformDispatcher.instance.locale.languageCode;
    if (supportedLanguageCodes.contains(deviceLocal)) {
      return deviceLocal;
    }
    return arabicLanguageCode;
  }

  /// Supported language codes in order of preference
  static const List<String> supportedLanguageCodes = [
    arabicLanguageCode,
    englishLanguageCode,
  ];

  /// Language key for final SharedPreferencesAsync _prefs
  static const String languageKey = 'selected_language';

  /// Convert app language code to API language code
  static String convertToApiLanguageCode(String? languageCode) {
    final String deviceLocal = PlatformDispatcher.instance.locale.languageCode;
    return switch (languageCode) {
      englishLanguageCode => _englishApiLanguageCode,
      arabicLanguageCode => _arabicApiLanguageCode,
      _ =>
        deviceLocal == arabicLanguageCode
            ? _arabicApiLanguageCode
            : _englishApiLanguageCode,
    };
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
