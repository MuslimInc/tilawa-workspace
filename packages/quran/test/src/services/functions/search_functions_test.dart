import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/services/functions/search_functions.dart';

void main() {
  group('search_functions', () {
    group('searchWords', () {
      test('returns results for common Arabic word', () {
        final Map<String, dynamic> result = searchWords('الله');
        expect(result['occurences'], greaterThan(0));
        expect(result['result'], isA<List>());
      });

      test('returns empty for non-existent word', () {
        final Map<String, dynamic> result = searchWords('xyznonexistent123');
        expect(result['occurences'], 0);
        expect((result['result'] as List).isEmpty, isTrue);
      });

      test('result contains surah and verse numbers', () {
        final Map<String, dynamic> result = searchWords('الحمد');
        expect(result['occurences'], greaterThan(0));
        final firstResult = (result['result'] as List).first;
        expect(firstResult['suraNumber'], isA<int>());
        expect(firstResult['verseNumber'], isA<int>());
      });

      test('limits results to 50', () {
        final Map<String, dynamic> result = searchWords('الله');
        expect(result['occurences'], lessThanOrEqualTo(50));
      });
    });

    group('normalise', () {
      test('removes tashkeel', () {
        final String result = normalise('بِسْمِ');
        expect(result.contains('\u064E'), isFalse);
        expect(result.contains('\u0650'), isFalse);
      });

      test('normalizes Alif variants', () {
        expect(normalise('أ'), 'ا');
        expect(normalise('إ'), 'ا');
        expect(normalise('آ'), 'ا');
      });

      test('normalizes Ya to Alif Maksura', () {
        expect(normalise('ي'), 'ى');
      });

      test('removes end of ayah symbol', () {
        expect(normalise('آية۝').contains('\u06DD'), isFalse);
      });

      test('preserves base letters', () {
        expect(normalise('محمد'), 'محمد');
      });
    });

    group('removeDiacritics', () {
      test('removes Fatha', () {
        expect(removeDiacritics('بَ'), 'ب');
      });

      test('removes Damma', () {
        expect(removeDiacritics('بُ'), 'ب');
      });

      test('removes Kasra', () {
        expect(removeDiacritics('بِ'), 'ب');
      });

      test('removes Shadda', () {
        expect(removeDiacritics('بّ'), 'ب');
      });

      test('removes Tanwin', () {
        expect(removeDiacritics('بً'), 'ب');
        expect(removeDiacritics('بٌ'), 'ب');
        expect(removeDiacritics('بٍ'), 'ب');
      });

      test('preserves base letters', () {
        expect(removeDiacritics('الله'), 'الله');
      });
    });
  });
}
