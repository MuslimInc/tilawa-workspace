import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/data/datasources/arabic_text_utils.dart';

void main() {
  group('ArabicTextUtils', () {
    group('normalize', () {
      test('should return empty string for empty input', () {
        expect(ArabicTextUtils.normalize(''), '');
      });

      test('should remove diacritics (Fatha)', () {
        // Fatha is the mark above ب
        expect(ArabicTextUtils.normalize('بَ'), 'ب');
      });

      test('should remove diacritics (Damma)', () {
        expect(ArabicTextUtils.normalize('بُ'), 'ب');
      });

      test('should remove diacritics (Kasra)', () {
        expect(ArabicTextUtils.normalize('بِ'), 'ب');
      });

      test('should remove diacritics (Sukun)', () {
        expect(ArabicTextUtils.normalize('بْ'), 'ب');
      });

      test('should remove diacritics (Shadda)', () {
        expect(ArabicTextUtils.normalize('بّ'), 'ب');
      });

      test('should remove Tanwin marks', () {
        expect(ArabicTextUtils.normalize('بٌ'), 'ب');
        expect(ArabicTextUtils.normalize('بً'), 'ب');
        expect(ArabicTextUtils.normalize('بٍ'), 'ب');
      });

      test('should remove Quranic marks (superscript Alef)', () {
        expect(ArabicTextUtils.normalize('هٰذا'), 'هذا');
      });

      test('should normalize Alef with Hamza above to plain Alef', () {
        expect(ArabicTextUtils.normalize('أحمد'), 'احمد');
      });

      test('should normalize Alef with Hamza below to plain Alef', () {
        expect(ArabicTextUtils.normalize('إبراهيم'), 'ابراهيم');
      });

      test('should normalize Alef with Madda to plain Alef', () {
        expect(ArabicTextUtils.normalize('آية'), 'ايه');
      });

      test('should normalize Alef Wasla to plain Alef', () {
        expect(ArabicTextUtils.normalize('ٱلله'), 'الله');
      });

      test('should normalize Alef Maqsura to Ya', () {
        expect(ArabicTextUtils.normalize('موسى'), 'موسي');
      });

      test('should normalize Ta Marbuta to Ha', () {
        expect(ArabicTextUtils.normalize('سورة'), 'سوره');
      });

      test('should handle combined normalizations', () {
        // "بِسْمِ ٱللَّهِ" with diacritics
        const input = 'بِسْمِ ٱللَّهِ';
        final String result = ArabicTextUtils.normalize(input);
        expect(result, 'بسم الله');
      });

      test('should preserve non-Arabic characters', () {
        expect(ArabicTextUtils.normalize('Hello World'), 'Hello World');
      });

      test('should handle mixed Arabic and English', () {
        expect(ArabicTextUtils.normalize('Surah الفاتحة'), 'Surah الفاتحه');
      });
    });

    group('containsArabic', () {
      test('should return true for Arabic text', () {
        expect(ArabicTextUtils.containsArabic('السلام'), true);
      });

      test('should return true for mixed Arabic and English', () {
        expect(ArabicTextUtils.containsArabic('Hello مرحبا'), true);
      });

      test('should return false for pure English text', () {
        expect(ArabicTextUtils.containsArabic('Hello World'), false);
      });

      test('should return false for empty string', () {
        expect(ArabicTextUtils.containsArabic(''), false);
      });

      test('should return false for numbers only', () {
        expect(ArabicTextUtils.containsArabic('12345'), false);
      });

      test('should return true for Arabic numbers', () {
        // Arabic-Indic numerals are in range 0600-06FF
        expect(ArabicTextUtils.containsArabic('١٢٣'), true);
      });
    });

    group('extractArabicOnly', () {
      test('should extract Arabic from mixed text', () {
        expect(
          ArabicTextUtils.extractArabicOnly('Hello السلام World'),
          ' السلام ',
        );
      });

      test('should return only spaces for pure English text', () {
        // 'Hello World' has one space, which is preserved
        expect(ArabicTextUtils.extractArabicOnly('Hello World'), ' ');
      });

      test('should preserve Arabic text', () {
        expect(
          ArabicTextUtils.extractArabicOnly('السلام عليكم'),
          'السلام عليكم',
        );
      });

      test('should remove numbers', () {
        expect(ArabicTextUtils.extractArabicOnly('سورة 1'), 'سورة ');
      });

      test('should handle empty string', () {
        expect(ArabicTextUtils.extractArabicOnly(''), '');
      });

      test('should preserve spaces', () {
        expect(
          ArabicTextUtils.extractArabicOnly('كلمة أولى كلمة ثانية'),
          'كلمة أولى كلمة ثانية',
        );
      });
    });
  });
}
