import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/services/quran_data_service_impl.dart';
import 'package:quran_qcf/src/services/quran_service_locator.dart';
import 'package:quran_qcf/src/services/search_service_impl.dart';
import 'package:quran_qcf/src/services/surah_service_impl.dart';
import 'package:quran_qcf/src/services/text_normalization_service_impl.dart';
import 'package:quran_qcf/src/services/verse_service_impl.dart';

void main() {
  group('QuranServiceLocator', () {
    test('quranDataService returns QuranDataServiceImpl', () {
      expect(QuranServiceLocator.quranDataService, isA<QuranDataServiceImpl>());
    });

    test('surahService returns SurahServiceImpl', () {
      expect(QuranServiceLocator.surahService, isA<SurahServiceImpl>());
    });

    test('verseService returns VerseServiceImpl', () {
      expect(QuranServiceLocator.verseService, isA<VerseServiceImpl>());
    });

    test('searchService returns SearchServiceImpl', () {
      expect(QuranServiceLocator.searchService, isA<SearchServiceImpl>());
    });

    test('textNormalizationService returns TextNormalizationServiceImpl', () {
      expect(
        QuranServiceLocator.textNormalizationService,
        isA<TextNormalizationServiceImpl>(),
      );
    });

    test('services are const instances (same reference)', () {
      // Access twice and verify they're the same instance
      const QuranDataServiceImpl service1 =
          QuranServiceLocator.quranDataService;
      const QuranDataServiceImpl service2 =
          QuranServiceLocator.quranDataService;
      expect(identical(service1, service2), isTrue);
    });

    test('quranDataService can get page data', () {
      final List<Map<String, int>> data = QuranServiceLocator.quranDataService
          .getPageData(1);
      expect(data, isNotEmpty);
    });

    test('surahService can get surah name', () {
      final String name = QuranServiceLocator.surahService.getName(1);
      expect(name, 'Al Fatiha');
    });

    test('verseService can get verse', () {
      final String verse = QuranServiceLocator.verseService.getVerse(1, 1);
      expect(verse, isNotEmpty);
    });

    test('searchService can search words', () {
      final Map<String, dynamic> result = QuranServiceLocator.searchService
          .searchWords('الحمد');
      expect(result['occurences'], greaterThan(0));
    });

    test('textNormalizationService can normalise text', () {
      final String result = QuranServiceLocator.textNormalizationService
          .normalise('أَحْمَد');
      expect(result, isNotEmpty);
    });
  });
}
