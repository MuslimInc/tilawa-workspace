import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/services/verse_service_impl.dart';

void main() {
  group('VerseServiceImpl', () {
    const verseService = VerseServiceImpl();

    test('getVerseQCF should separate characters with spaces', () {
      // Surah 1, Verse 1: 'ﱁﱂﱃﱄﱅ'
      // Expected: 'ﱁ ﱂ ﱃ ﱄ ﱅ'
      final String result = verseService.getVerseQCF(1, 1);
      expect(result, 'ﱁ ﱂ ﱃ ﱄ ﱅ');
    });

    test('getVerseQCF should separate characters with spaces', () {
      // Surah 1, Verse 1: 'ﱁﱂﱃﱄﱅ'
      // Expected: 'ﱁ ﱂ ﱃ ﱄ ﱅ'
      final String result = verseService.getVerseQCF(1, 1);
      expect(result, 'ﱁ ﱂ ﱃ ﱄ ﱅ');
    });

    test('getVerseQCF should respect verseEndSymbol=false', () {
      // Surah 1, Verse 1: 'ﱁﱂﱃﱄﱅ'
      // Last char is verse number/symbol.
      // Expected without symbol: 'ﱁ ﱂ ﱃ ﱄ'
      final String result = verseService.getVerseQCF(
        1,
        1,
        verseEndSymbol: false,
      );
      expect(result, 'ﱁ ﱂ ﱃ ﱄ');
    });

    test('getVerseNumberQCF should return only the last character', () {
      // Surah 1, Verse 1: 'ﱁﱂﱃﱄﱅ' -> Last char is 'ﱅ'
      final String result = verseService.getVerseNumberQCF(1, 1);
      expect(result, 'ﱅ');
    });

    test(
      'getVerseQCF should work normally for verseEndSymbol=false with new data',
      () {
        final String result = verseService.getVerseQCF(
          2,
          45,
          verseEndSymbol: false,
        );

        // We expect the marker 'ﲩ' to be removed.
        expect(
          result.contains('ﲩ'),
          false,
          reason: 'Marker ﲩ should be removed from verse 2:45',
        );
      },
    );
  });
}
