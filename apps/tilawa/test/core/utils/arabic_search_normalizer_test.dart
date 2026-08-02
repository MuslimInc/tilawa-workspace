import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/utils/arabic_search_normalizer.dart';

void main() {
  group('ArabicSearchNormalizer', () {
    test('strips tashkeel and tatweel', () {
      expect(
        ArabicSearchNormalizer.normalize('بِسْمِ اللَّهِ'),
        ArabicSearchNormalizer.normalize('بسم الله'),
      );
      expect(ArabicSearchNormalizer.normalize('الرّحـمن'), 'الرحمن');
    });

    test('folds alef and hamza variants', () {
      expect(ArabicSearchNormalizer.normalize('أحمد'), 'احمد');
      expect(ArabicSearchNormalizer.normalize('إحمد'), 'احمد');
      expect(ArabicSearchNormalizer.normalize('آحمد'), 'احمد');
      expect(ArabicSearchNormalizer.normalize('ٱحمد'), 'احمد');
    });

    test('folds alef maqsura to ya', () {
      expect(ArabicSearchNormalizer.normalize('على'), 'علي');
      expect(ArabicSearchNormalizer.normalize('علي'), 'علي');
    });

    test('query with marks matches unmarked text via contains', () {
      final String haystack = ArabicSearchNormalizer.normalize(
        'قُلْ هُوَ اللَّهُ أَحَدٌ',
      );
      final String needle = ArabicSearchNormalizer.normalize('قل هو الله احد');
      expect(haystack.contains(needle), isTrue);
    });
  });
}
