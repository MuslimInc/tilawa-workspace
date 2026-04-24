import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';

void main() {
  group('page_functions', () {
    group('getPageData', () {
      test('returns data for page 1', () {
        final List<PageSurahEntry> data = getPageData(1);
        expect(data, isNotEmpty);
        expect(data.first.surah, 1);
      });

      test('returns data for page 604', () {
        final List<PageSurahEntry> data = getPageData(604);
        expect(data, isNotEmpty);
      });

      test('throws for page 0', () {
        expect(() => getPageData(0), throwsA(isA<QuranException>()));
      });

      test('throws for page 605', () {
        expect(() => getPageData(605), throwsA(isA<QuranException>()));
      });
    });

    group('getSurahCountByPage', () {
      test('page 1 has 1 surah', () {
        expect(getSurahCountByPage(1), 1);
      });

      test('page 2 has 1 surah', () {
        expect(getSurahCountByPage(2), 1);
      });

      test('throws for invalid page', () {
        expect(() => getSurahCountByPage(0), throwsA(isA<QuranException>()));
      });
    });

    group('getVerseCountByPage', () {
      test('returns positive count for page 1', () {
        expect(getVerseCountByPage(1), greaterThan(0));
      });

      test('returns positive count for page 604', () {
        expect(getVerseCountByPage(604), greaterThan(0));
      });

      test('throws for invalid page', () {
        expect(() => getVerseCountByPage(0), throwsA(isA<QuranException>()));
      });
    });

    group('getJuzNumber', () {
      test('Al-Fatiha 1:1 is in Juz 1', () {
        expect(getJuzNumber(1, 1), 1);
      });

      test('Al-Baqarah 2:142 is in Juz 2', () {
        expect(getJuzNumber(2, 142), 2);
      });

      test('returns -1 for invalid verse', () {
        expect(getJuzNumber(1, 100), -1);
      });
    });

    group('getPageNumber', () {
      test('Al-Fatiha 1:1 is on page 1', () {
        expect(getPageNumber(1, 1), 1);
      });

      test('Al-Baqarah 2:1 is on page 2', () {
        expect(getPageNumber(2, 1), 2);
      });

      test('throws for invalid surah', () {
        expect(() => getPageNumber(0, 1), throwsA(isA<QuranException>()));
        expect(() => getPageNumber(115, 1), throwsA(isA<QuranException>()));
      });

      test('throws for invalid verse', () {
        expect(() => getPageNumber(1, 100), throwsA(isA<QuranException>()));
      });
    });
  });
}
