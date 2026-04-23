import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';

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

    test('services are accessible via QuranServiceLocator', () {
      // Verify services can be accessed through the locator
      final QuranDataService quranDataService =
          QuranServiceLocator.quranDataService;
      final SurahService surahService = QuranServiceLocator.surahService;
      final VerseService verseService = QuranServiceLocator.verseService;
      final SearchService searchService = QuranServiceLocator.searchService;
      final TextNormalizationService textNormalizationService =
          QuranServiceLocator.textNormalizationService;

      expect(quranDataService, isNotNull);
      expect(surahService, isNotNull);
      expect(verseService, isNotNull);
      expect(searchService, isNotNull);
      expect(textNormalizationService, isNotNull);
    });

    test('quranDataService can get page data', () {
      final List<PageSurahEntry> data = QuranServiceLocator.quranDataService
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
      final SearchResult result = QuranServiceLocator.searchService.searchWords(
        'الحمد',
      );
      expect(result.occurrences, greaterThan(0));
    });

    test('textNormalizationService can normalise text', () {
      final String result = QuranServiceLocator.textNormalizationService
          .normalise('أَحْمَد');
      expect(result, isNotEmpty);
    });
  });
}
