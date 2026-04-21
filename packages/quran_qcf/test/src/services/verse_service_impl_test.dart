import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/quran_exception.dart';
import 'package:quran_qcf/src/services/verse_service_impl.dart';

void main() {
  late VerseServiceImpl service;

  setUp(() {
    service = const VerseServiceImpl();
  });

  group('VerseServiceImpl', () {
    group('getVerse', () {
      test('returns verse for Al-Fatiha 1:1', () {
        final String verse = service.getVerse(1, 1);
        expect(verse, isNotEmpty);
      });

      test('returns verse without end symbol by default', () {
        final String verse = service.getVerse(1, 1);
        expect(verse.contains('\u06dd'), isFalse);
      });

      test('returns verse with end symbol when requested', () {
        final String verse = service.getVerse(1, 1, verseEndSymbol: true);
        expect(verse.contains('\u06dd'), isTrue);
      });

      test('throws for invalid surah/verse', () {
        expect(() => service.getVerse(999, 1), throwsA(isA<QuranException>()));
      });
    });

    group('getVerseEndSymbol', () {
      test('returns symbol with Arabic numerals by default', () {
        final String symbol = service.getVerseEndSymbol(1);
        expect(symbol, contains('\u06dd'));
        expect(symbol, contains('۱'));
      });

      test('returns symbol with Western numerals when arabicNumeral=false', () {
        final String symbol = service.getVerseEndSymbol(
          123,
          arabicNumeral: false,
        );
        expect(symbol, '\u06dd123');
      });

      test('converts multi-digit numbers correctly', () {
        final String symbol = service.getVerseEndSymbol(286);
        expect(symbol, contains('\u06dd'));
        expect(symbol, contains('۲'));
        expect(symbol, contains('۸'));
        expect(symbol, contains('٦'));
      });
    });

    group('getVerseQCF', () {
      test('returns QCF verse for valid surah/verse', () {
        final String verse = service.getVerseQCF(1, 1);
        expect(verse, isNotEmpty);
      });

      test('throws for invalid verse', () {
        expect(
          () => service.getVerseQCF(999, 1),
          throwsA(isA<QuranException>()),
        );
      });
    });

    group('getVerseNumberQCF', () {
      test('returns QCF verse number for valid verse', () {
        final String number = service.getVerseNumberQCF(1, 1);
        expect(number, isNotEmpty);
        expect(number.length, 1);
      });

      test('throws for invalid verse', () {
        expect(
          () => service.getVerseNumberQCF(999, 1),
          throwsA(isA<QuranException>()),
        );
      });
    });
  });
}
