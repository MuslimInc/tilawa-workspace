import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/services/search_service_impl.dart';

void main() {
  late SearchServiceImpl service;

  setUp(() {
    service = const SearchServiceImpl();
  });

  group('SearchServiceImpl', () {
    group('searchWords', () {
      test('returns results for common Arabic word', () {
        final Map<String, dynamic> result = service.searchWords('الله');
        expect(result['occurences'], greaterThan(0));
        expect(result['result'], isA<List>());
      });

      test('returns empty result for non-existent word', () {
        final Map<String, dynamic> result = service.searchWords(
          'xyznonexistent',
        );
        expect(result['occurences'], 0);
        expect((result['result'] as List).isEmpty, isTrue);
      });

      test('result contains surah and verse numbers', () {
        final Map<String, dynamic> result = service.searchWords('الحمد');
        expect(result['occurences'], greaterThan(0));
        final firstResult = (result['result'] as List).first;
        expect(firstResult['suraNumber'], isA<int>());
        expect(firstResult['verseNumber'], isA<int>());
      });

      test('limits results to 50', () {
        // Search for a very common word
        final Map<String, dynamic> result = service.searchWords('الله');
        expect(result['occurences'], lessThanOrEqualTo(50));
      });

      test('search is case-insensitive for Latin characters', () {
        final Map<String, dynamic> result1 = service.searchWords('allah');
        final Map<String, dynamic> result2 = service.searchWords('ALLAH');
        // Both should return same count (may be 0 if only Arabic is indexed)
        expect(result1['occurences'], result2['occurences']);
      });

      test('falls back to content search when text_normal has no match', () {
        // Search for a character that exists in content but not in text_normal
        // The small superscript alef (ٰ) or sukun (ۡ) appears in content
        // but is stripped from text_normal
        // Use a unique diacritical pattern from content field
        final Map<String, dynamic> result = service.searchWords('بِسۡمِ');
        // This should find results via the content fallback
        expect(result['occurences'], greaterThan(0));
      });
    });
  });
}
