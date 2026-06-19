import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';

void main() {
  group('AudioExtras', () {
    test('getString returns strings and converts numeric values', () {
      final extras = <String, dynamic>{
        AudioExtrasKeys.reciterId: '7',
        AudioExtrasKeys.moshafId: 1,
        'fraction': 1.5,
        'malformed': true,
      };

      expect(extras.getString(AudioExtrasKeys.reciterId), '7');
      expect(extras.getString(AudioExtrasKeys.moshafId), '1');
      expect(extras.getString('fraction'), '1.5');
      expect(extras.getString('malformed'), isNull);
      expect(extras.getString('missing'), isNull);
    });

    test('getInt returns ints and parses numeric strings', () {
      final extras = <String, dynamic>{
        AudioExtrasKeys.surahId: 2,
        AudioExtrasKeys.moshafId: '1',
        AudioExtrasKeys.reciterId: 'not-number',
      };

      expect(extras.getInt(AudioExtrasKeys.surahId), 2);
      expect(extras.getInt(AudioExtrasKeys.moshafId), 1);
      expect(extras.getInt(AudioExtrasKeys.reciterId), isNull);
      expect(extras.getInt('missing'), isNull);
    });

    test('nullable extras return null for all readers', () {
      const Map<String, dynamic>? extras = null;

      expect(extras.getString(AudioExtrasKeys.reciterId), isNull);
      expect(extras.getInt(AudioExtrasKeys.moshafId), isNull);
    });
  });
}
