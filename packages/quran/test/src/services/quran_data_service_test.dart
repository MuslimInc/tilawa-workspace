import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/services/quran_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await QuranDataService.instance.ensureLoaded();
  });

  group('QuranDataService verse-end detection', () {
    test('returns the last word index for a verse', () {
      expect(QuranDataService.instance.getLastWordIndexForVerse(1, 1), 5);
    });

    test('identifies verse-end words correctly', () {
      expect(
        QuranDataService.instance.isVerseEndWord({
          'surah': '1',
          'ayah': '1',
          'word': '5',
        }),
        isTrue,
      );
      expect(
        QuranDataService.instance.isVerseEndWord({
          'surah': '1',
          'ayah': '1',
          'word': '4',
        }),
        isFalse,
      );
    });
  });
}
