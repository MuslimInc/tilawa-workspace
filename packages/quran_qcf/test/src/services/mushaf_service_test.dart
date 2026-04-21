import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/services/mushaf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await MushafService.instance.ensureLoaded();
  });

  group('MushafService verse-end detection', () {
    test('returns the last word index for a verse', () {
      expect(MushafService.instance.getLastWordIndexForVerse(1, 1), 5);
    });

    test('identifies verse-end words correctly', () {
      expect(
        MushafService.instance.isVerseEndWord({
          'surah': '1',
          'ayah': '1',
          'word': '5',
        }),
        isTrue,
      );
      expect(
        MushafService.instance.isVerseEndWord({
          'surah': '1',
          'ayah': '1',
          'word': '4',
        }),
        isFalse,
      );
    });
  });
}
