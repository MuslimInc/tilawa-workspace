import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/utils/surah_names.dart';

void main() {
  group('SurahNames', () {
    group('getArabicSurahName', () {
      test('should return correct Arabic name for Surah 1', () {
        // act
        final String result = SurahNames.getArabicSurahName(1);

        // assert
        expect(result, 'سورة الفاتحة');
      });

      test('should return correct Arabic name for Surah 2', () {
        // act
        final String result = SurahNames.getArabicSurahName(2);

        // assert
        expect(result, 'سورة البقرة');
      });

      test('should return correct Arabic name for Surah 114', () {
        // act
        final String result = SurahNames.getArabicSurahName(114);

        // assert
        expect(result, 'سورة الناس');
      });

      test('should return default message for invalid surah number', () {
        // act
        final String result = SurahNames.getArabicSurahName(115);

        // assert
        expect(result, 'سورة غير معروفة');
      });

      test('should return default message for zero', () {
        // act
        final String result = SurahNames.getArabicSurahName(0);

        // assert
        expect(result, 'سورة غير معروفة');
      });

      test('should return default message for negative number', () {
        // act
        final String result = SurahNames.getArabicSurahName(-1);

        // assert
        expect(result, 'سورة غير معروفة');
      });

      test('should return correct names for all valid surahs', () {
        // Verify all 114 surahs have names
        for (var i = 1; i <= 114; i++) {
          final String result = SurahNames.getArabicSurahName(i);
          expect(result, isNot('سورة غير معروفة'));
          expect(result, startsWith('سورة'));
        }
      });
    });

    group('getEnglishSurahName', () {
      test('should return correct English name for Surah 1', () {
        // act
        final String result = SurahNames.getEnglishSurahName(1);

        // assert
        expect(result, 'Al-Fatihah');
      });

      test('should return correct English name for Surah 2', () {
        // act
        final String result = SurahNames.getEnglishSurahName(2);

        // assert
        expect(result, 'Al-Baqarah');
      });

      test('should return correct English name for Surah 114', () {
        // act
        final String result = SurahNames.getEnglishSurahName(114);

        // assert
        expect(result, 'An-Nas');
      });

      test('should return default message for invalid surah number', () {
        // act
        final String result = SurahNames.getEnglishSurahName(115);

        // assert
        expect(result, 'Unknown Surah');
      });

      test('should return default message for zero', () {
        // act
        final String result = SurahNames.getEnglishSurahName(0);

        // assert
        expect(result, 'Unknown Surah');
      });

      test('should return default message for negative number', () {
        // act
        final String result = SurahNames.getEnglishSurahName(-1);

        // assert
        expect(result, 'Unknown Surah');
      });

      test('should return correct names for all valid surahs', () {
        // Verify all 114 surahs have English names
        for (var i = 1; i <= 114; i++) {
          final String result = SurahNames.getEnglishSurahName(i);
          expect(result, isNot('Unknown Surah'));
          expect(result, isNotEmpty);
        }
      });

      test('should have unique names for different surahs', () {
        final names = <String>{};
        for (var i = 1; i <= 114; i++) {
          final String name = SurahNames.getEnglishSurahName(i);
          names.add(name);
        }
        // All 114 names should be unique
        expect(names.length, 114);
      });
    });
  });
}
