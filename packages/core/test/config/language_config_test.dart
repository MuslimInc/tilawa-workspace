import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/config/language_config.dart';

void main() {
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
