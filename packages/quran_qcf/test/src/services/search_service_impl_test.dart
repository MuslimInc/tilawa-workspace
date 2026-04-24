import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';

void main() {
  late SearchServiceImpl service;

  setUp(() {
    service = const SearchServiceImpl();
  });

  group('SearchServiceImpl', () {
    group('searchWords', () {
      test('returns results for common Arabic word', () {
        final SearchResult result = service.searchWords('الله');
        expect(result.occurrences, greaterThan(0));
        expect(result.entries, isA<List>());
      });

      test('returns empty result for non-existent word', () {
        final SearchResult result = service.searchWords('xyznonexistent');
        expect(result.occurrences, 0);
        expect(result.entries.isEmpty, isTrue);
      });

      test('result contains surah and verse numbers', () {
        final SearchResult result = service.searchWords('الحمد');
        expect(result.occurrences, greaterThan(0));
        final SearchEntry firstResult = result.entries.first;
        expect(firstResult.surahNumber, isA<int>());
        expect(firstResult.verseNumber, isA<int>());
      });

      test('limits results to 50', () {
        // Search for a very common word
        final SearchResult result = service.searchWords('الله');
        expect(result.entries.length, lessThanOrEqualTo(50));
      });

      test('search is case-insensitive for Latin characters', () {
        final SearchResult result1 = service.searchWords('allah');
        final SearchResult result2 = service.searchWords('ALLAH');
        // Both should return same count (may be 0 if only Arabic is indexed)
        expect(result1.occurrences, result2.occurrences);
      });

      test('falls back to content search when text_normal has no match', () {
        // Search for a character that exists in content but not in text_normal
        // The small superscript alef (ٰ) or sukun (ۡ) appears in content
        // but is stripped from text_normal
        // Use a unique diacritical pattern from content field
        final SearchResult result = service.searchWords('بِسۡمِ');
        // This should find results via the content fallback
        expect(result.occurrences, greaterThan(0));
      });
    });
  });
}
