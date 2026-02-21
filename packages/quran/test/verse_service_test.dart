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

    test('getVerseQCF should handle newlines correctly', () {
      // Surah 2, Verse 2 has a newline in quran_text.dart: 'ﱃﱄﱅﱆﱇﱈﱉﱊ\nﱋﱌ'
      // We expect the newline to be treated as a separator or ignored, but definitely not broken.
      // Current implementation splits by '' then joins ' '.
      // If newline exists, it will become ' \n ' in the output if not stripped.
      // Let's see what happens.
      final String result = verseService.getVerseQCF(2, 2);

      // Ensure newline is preserved (surrounded by spaces due to join)
      expect(
        result.contains('\n'),
        true,
        reason: 'Output should contain newlines as requested',
      );

      // Ensure spaces between chars
      expect(
        result.contains('  '),
        false,
        reason: 'Should not have double spaces',
      );
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
      'getVerseQCF should handle trailing newlines for verseEndSymbol=false',
      () {
        // Surah 2, Verse 45: '\nﲠﲡﲢﲣﲤﲥﲦﲧﲨﲩ\n'
        // Last char is '\n'. Marker is 'ﲩ'.
        // If we don't handle '\n', it will remove '\n' and leave 'ﲩ'.
        final String result = verseService.getVerseQCF(
          2,
          45,
          verseEndSymbol: false,
        );

        // We expect the marker 'ﲩ' to be removed even if there is a trailing newline.
        expect(
          result.contains('ﲩ'),
          false,
          reason: 'Marker ﲩ should be removed from verse 2:45',
        );
      },
    );
  });
}
