import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/config/language_config.dart';

void main() {
  group('LanguageConfig', () {
    test('defaultLanguageCode is Arabic', () {
      expect(LanguageConfig.defaultLanguageCode, arabicLanguageCode);
    });

    test('convertToApiLanguageCode defaults to Arabic', () {
      expect(LanguageConfig.convertToApiLanguageCode(null), 'ar');
      expect(LanguageConfig.convertToApiLanguageCode('fr'), 'ar');
    });
  });

  group('LanguageConfig.emojiForLanguageCode', () {
    test('returns Arabic emoji for ar', () {
      expect(
        LanguageConfig.emojiForLanguageCode(arabicLanguageCode),
        arabicLanguageEmoji,
      );
    });

    test('returns English emoji for en', () {
      expect(
        LanguageConfig.emojiForLanguageCode(englishLanguageCode),
        englishLanguageEmoji,
      );
    });

    test('returns empty string for unsupported codes', () {
      expect(LanguageConfig.emojiForLanguageCode('fr'), '');
    });
  });
}
