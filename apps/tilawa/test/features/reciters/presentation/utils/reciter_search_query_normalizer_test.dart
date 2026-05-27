import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciter_search_query_normalizer.dart';

void main() {
  group('ReciterSearchQueryNormalizer', () {
    test('matches Arabic names with alef variants', () {
      expect(
        ReciterSearchQueryNormalizer.matches(
          query: 'ابراهيم',
          reciterName: 'إبراهيم بن محمد',
          reciterLetter: 'ا',
        ),
        isTrue,
      );
    });

    test('matches when query uses Arabic digits', () {
      expect(
        ReciterSearchQueryNormalizer.matches(
          query: 'سورة ١',
          reciterName: 'قارئ سورة 1',
          reciterLetter: 'س',
        ),
        isTrue,
      );
    });

    test('normalizes ta marbuta for forgiving search', () {
      expect(
        ReciterSearchQueryNormalizer.matches(
          query: 'رحمه',
          reciterName: 'عبد الرحمة',
          reciterLetter: 'ع',
        ),
        isTrue,
      );
    });

    test('returns false when query does not match', () {
      expect(
        ReciterSearchQueryNormalizer.matches(
          query: 'zzzz',
          reciterName: 'مشاري العفاسي',
          reciterLetter: 'م',
        ),
        isFalse,
      );
    });
  });
}
