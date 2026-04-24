import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';

void main() {
  group('search_functions', () {
    group('searchWords', () {
      test('returns results for common Arabic word', () {
        final SearchResult result = searchWords('الله');
        expect(result.occurrences, greaterThan(0));
        expect(result.entries, isA<List>());
      });

      test('returns empty for non-existent word', () {
        final SearchResult result = searchWords('xyznonexistent123');
        expect(result.occurrences, 0);
        expect(result.entries.isEmpty, isTrue);
      });

      test('result contains surah and verse numbers', () {
        final SearchResult result = searchWords('الحمد');
        expect(result.occurrences, greaterThan(0));
        final SearchEntry firstResult = result.entries.first;
        expect(firstResult.surahNumber, isA<int>());
        expect(firstResult.verseNumber, isA<int>());
      });

      test('limits results to 50', () {
        final SearchResult result = searchWords('الله');
        expect(result.entries.length, lessThanOrEqualTo(50));
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
