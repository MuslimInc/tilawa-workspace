import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/quran_exception.dart';
import 'package:quran_qcf/src/services/functions/verse_functions.dart';

void main() {
  group('verse_functions', () {
    group('getVerse', () {
      test('returns verse for Al-Fatiha 1:1', () {
        final String verse = getVerse(1, 1);
        expect(verse, isNotEmpty);
      });

      test('returns verse without end symbol by default', () {
        final String verse = getVerse(1, 1);
        expect(verse.contains('\u06dd'), isFalse);
      });

      test('returns verse with end symbol when requested', () {
        final String verse = getVerse(1, 1, verseEndSymbol: true);
        expect(verse.contains('\u06dd'), isTrue);
      });

      test('throws for invalid verse', () {
        expect(() => getVerse(999, 1), throwsA(isA<QuranException>()));
      });
    });

    group('getVerseEndSymbol', () {
      test('returns symbol with Arabic numerals', () {
        final String symbol = getVerseEndSymbol(1);
        expect(symbol, contains('\u06dd'));
        expect(symbol, contains('۱'));
      });

      test('returns symbol with Western numerals', () {
        final String symbol = getVerseEndSymbol(123, arabicNumeral: false);
        expect(symbol, '\u06dd123');
      });

      test('converts multi-digit numbers', () {
        final String symbol = getVerseEndSymbol(286);
        expect(symbol, contains('\u06dd'));
      });
    });

    group('getVerseQCF', () {
      test('returns QCF verse for valid input', () {
        final String verse = getVerseQCF(1, 1);
        expect(verse, isNotEmpty);
      });

      test('returns QCF verse with end symbol by default', () {
        final String verseWith = getVerseQCF(1, 1);
        final String verseWithout = getVerseQCF(1, 1, verseEndSymbol: false);
        expect(verseWith.length, greaterThan(verseWithout.length));
      });

      test('throws for invalid verse', () {
        expect(() => getVerseQCF(999, 1), throwsA(isA<QuranException>()));
      });
    });

    group('getVerseNumberQCF', () {
      test('returns QCF verse number', () {
        final String number = getVerseNumberQCF(1, 1);
        expect(number, isNotEmpty);
        expect(number.length, 1);
      });

      test('throws for invalid verse', () {
        expect(() => getVerseNumberQCF(999, 1), throwsA(isA<QuranException>()));
      });
    });
  });
}
