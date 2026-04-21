import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/quran_exception.dart';
import 'package:quran_qcf/src/services/surah_service_impl.dart';

void main() {
  late SurahServiceImpl service;

  setUp(() {
    service = const SurahServiceImpl();
  });

  group('SurahServiceImpl', () {
    group('getName', () {
      test('returns name for Al-Fatiha', () {
        expect(service.getName(1), 'Al Fatiha');
      });

      test('returns name for Al-Baqarah', () {
        expect(service.getName(2), 'Al Baqarah');
      });

      test('returns name for An-Nas (114)', () {
        expect(service.getName(114), isNotEmpty);
      });

      test('throws for surah 0', () {
        expect(() => service.getName(0), throwsA(isA<QuranException>()));
      });

      test('throws for surah 115', () {
        expect(() => service.getName(115), throwsA(isA<QuranException>()));
      });

      test('throws for negative surah', () {
        expect(() => service.getName(-1), throwsA(isA<QuranException>()));
      });
    });

    group('getNameArabic', () {
      test('returns Arabic name for Al-Fatiha', () {
        expect(service.getNameArabic(1), 'الفاتحة');
      });

      test('returns Arabic name for Al-Baqarah', () {
        expect(service.getNameArabic(2), 'البقرة');
      });

      test('throws for invalid surah', () {
        expect(() => service.getNameArabic(0), throwsA(isA<QuranException>()));
      });
    });

    group('getPlaceOfRevelation', () {
      test('Al-Fatiha revealed in Makkah', () {
        expect(service.getPlaceOfRevelation(1), 'Makkah');
      });

      test('Al-Baqarah revealed in Madinah', () {
        expect(service.getPlaceOfRevelation(2), 'Madinah');
      });

      test('throws for invalid surah', () {
        expect(
          () => service.getPlaceOfRevelation(0),
          throwsA(isA<QuranException>()),
        );
      });
    });

    group('getVerseCount', () {
      test('Al-Fatiha has 7 verses', () {
        expect(service.getVerseCount(1), 7);
      });

      test('Al-Baqarah has 286 verses', () {
        expect(service.getVerseCount(2), 286);
      });

      test('Al-Kawthar has 3 verses', () {
        expect(service.getVerseCount(108), 3);
      });

      test('throws for invalid surah', () {
        expect(() => service.getVerseCount(0), throwsA(isA<QuranException>()));
      });
    });

    group('getSurahInfo', () {
      test('returns info for Al-Fatiha', () {
        expect(service.getSurahInfo(1), contains('سورة الفاتحة'));
      });

      test('throws for invalid surah', () {
        expect(() => service.getSurahInfo(0), throwsA(isA<QuranException>()));
      });
    });

    group('getSurahNames', () {
      test('returns alternative names for Al-Fatiha', () {
        expect(service.getSurahNames(1), contains('الْفَاتِحَةُ'));
      });
    });
  });
}
