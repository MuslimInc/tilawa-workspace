import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/quran_exception.dart';
import 'package:quran_qcf/src/services/quran_data_service_impl.dart';

void main() {
  late QuranDataServiceImpl service;

  setUp(() {
    service = const QuranDataServiceImpl();
  });

  group('QuranDataServiceImpl', () {
    group('getPageData', () {
      test('returns data for valid page 1', () {
        final List<Map<String, int>> data = service.getPageData(1);
        expect(data, isNotEmpty);
        expect(data.first['surah'], 1); // Al-Fatiha
      });

      test('returns data for valid page 604', () {
        final List<Map<String, int>> data = service.getPageData(604);
        expect(data, isNotEmpty);
      });

      test('throws QuranException for page 0', () {
        expect(() => service.getPageData(0), throwsA(isA<QuranException>()));
      });

      test('throws QuranException for page 605', () {
        expect(() => service.getPageData(605), throwsA(isA<QuranException>()));
      });

      test('throws QuranException for negative page', () {
        expect(() => service.getPageData(-1), throwsA(isA<QuranException>()));
      });
    });

    group('getSurahCountByPage', () {
      test('page 1 has 1 surah (Al-Fatiha)', () {
        expect(service.getSurahCountByPage(1), 1);
      });

      test('page 2 has 1 surah (Al-Baqarah start)', () {
        expect(service.getSurahCountByPage(2), 1);
      });

      test('throws for invalid page', () {
        expect(
          () => service.getSurahCountByPage(0),
          throwsA(isA<QuranException>()),
        );
      });
    });

    group('getVerseCountByPage', () {
      test('returns positive count for valid page', () {
        final int count = service.getVerseCountByPage(1);
        expect(count, greaterThan(0));
      });

      test('throws for invalid page', () {
        expect(
          () => service.getVerseCountByPage(0),
          throwsA(isA<QuranException>()),
        );
      });
    });

    group('getJuzNumber', () {
      test('Al-Fatiha 1:1 is in Juz 1', () {
        expect(service.getJuzNumber(1, 1), 1);
      });

      test('Al-Fatiha 1:7 is in Juz 1', () {
        expect(service.getJuzNumber(1, 7), 1);
      });

      test('Al-Baqarah 2:141 is in Juz 1', () {
        expect(service.getJuzNumber(2, 141), 1);
      });

      test('Al-Baqarah 2:142 is in Juz 2', () {
        expect(service.getJuzNumber(2, 142), 2);
      });

      test('returns -1 for invalid verse', () {
        expect(service.getJuzNumber(1, 100), -1);
      });
    });

    group('getPageNumber', () {
      test('Al-Fatiha 1:1 is on page 1', () {
        expect(service.getPageNumber(1, 1), 1);
      });

      test('Al-Baqarah 2:1 is on page 2', () {
        expect(service.getPageNumber(2, 1), 2);
      });

      test('throws for invalid surah number', () {
        expect(
          () => service.getPageNumber(0, 1),
          throwsA(isA<QuranException>()),
        );
        expect(
          () => service.getPageNumber(115, 1),
          throwsA(isA<QuranException>()),
        );
      });

      test('throws for invalid verse number', () {
        expect(
          () => service.getPageNumber(1, 100),
          throwsA(isA<QuranException>()),
        );
      });
    });
  });
}
