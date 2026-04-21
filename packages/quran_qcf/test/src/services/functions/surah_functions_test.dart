import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/quran_exception.dart';
import 'package:quran_qcf/src/services/functions/surah_functions.dart';

void main() {
  group('surah_functions', () {
    group('getSurahName', () {
      test('returns name for Al-Fatiha', () {
        expect(getSurahName(1), 'Al Fatiha');
      });

      test('returns name for Al-Baqarah', () {
        expect(getSurahName(2), 'Al Baqarah');
      });

      test('returns name for An-Nas', () {
        expect(getSurahName(114), isNotEmpty);
      });

      test('throws for surah 0', () {
        expect(() => getSurahName(0), throwsA(isA<QuranException>()));
      });

      test('throws for surah 115', () {
        expect(() => getSurahName(115), throwsA(isA<QuranException>()));
      });
    });

    group('getSurahNameEnglish', () {
      test('returns English name for Al-Fatiha', () {
        expect(getSurahNameEnglish(1), 'Al Fatiha');
      });

      test('returns English name for Al-Baqarah', () {
        expect(getSurahNameEnglish(2), 'Al Baqarah');
      });

      test('throws for invalid surah', () {
        expect(() => getSurahNameEnglish(0), throwsA(isA<QuranException>()));
      });
    });

    group('getSurahNameArabic', () {
      test('returns Arabic name for Al-Fatiha', () {
        expect(getSurahNameArabic(1), 'الفاتحة');
      });

      test('returns Arabic name for Al-Baqarah', () {
        expect(getSurahNameArabic(2), 'البقرة');
      });

      test('throws for invalid surah', () {
        expect(() => getSurahNameArabic(0), throwsA(isA<QuranException>()));
      });
    });

    group('getPlaceOfRevelation', () {
      test('Al-Fatiha revealed in Makkah', () {
        expect(getPlaceOfRevelation(1), 'Makkah');
      });

      test('Al-Baqarah revealed in Madinah', () {
        expect(getPlaceOfRevelation(2), 'Madinah');
      });

      test('throws for invalid surah', () {
        expect(() => getPlaceOfRevelation(0), throwsA(isA<QuranException>()));
      });
    });

    group('getVerseCount', () {
      test('Al-Fatiha has 7 verses', () {
        expect(getVerseCount(1), 7);
      });

      test('Al-Baqarah has 286 verses', () {
        expect(getVerseCount(2), 286);
      });

      test('Al-Kawthar has 3 verses', () {
        expect(getVerseCount(108), 3);
      });

      test('throws for invalid surah', () {
        expect(() => getVerseCount(0), throwsA(isA<QuranException>()));
      });
    });
  });
}
