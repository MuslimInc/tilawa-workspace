import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/data/repositories/mushaf_service.dart';
import 'package:quran_qcf/src/domain/models/quran_models.dart';

const String _fakeQpcV4Json = '''
{
  "w1": {"text": "A", "surah": "1", "ayah": "1", "word": "1"},
  "w2": {"text": "B", "surah": "1", "ayah": "1", "word": "2"},
  "w3": {"text": "C", "surah": "1", "ayah": "1", "word": "3"},
  "w4": {"text": "D", "surah": "1", "ayah": "1", "word": "4"},
  "w5": {"text": "E", "surah": "1", "ayah": "1", "word": "5"}
}
''';

const String _fakePageIndexJson = '''
{
  "1": {
    "1": ["w1", "w2", "w3", "w4", "w5"]
  }
}
''';

void _registerFakeAssets() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    late final String key;
    try {
      key = utf8.decode(message!.buffer.asUint8List());
    } catch (_) {
      return null;
    }

    if (key == 'packages/quran_qcf/assets/quran_fonts/qpc-v4.json') {
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(_fakeQpcV4Json)),
      );
    }

    if (key == 'packages/quran_qcf/assets/quran_fonts/quran_page_index.json') {
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(_fakePageIndexJson)),
      );
    }

    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafService mushafService;

  setUpAll(() async {
    _registerFakeAssets();
    mushafService = MushafService();
    await mushafService.ensureLoaded();
  });

  group('MushafService verse-end detection', () {
    test('returns the last word index for a verse', () {
      expect(mushafService.getLastWordIndexForVerse(1, 1), 5);
    });

    test('identifies verse-end words correctly', () {
      expect(
        mushafService.isVerseEndWord(
          const WordData(
            surah: 1,
            ayah: 1,
            wordIndex: 4,
            text: 'E',
            page: 1,
            line: 1,
            charType: 'end',
          ),
        ),
        isTrue,
      );
      expect(
        mushafService.isVerseEndWord(
          const WordData(
            surah: 1,
            ayah: 1,
            wordIndex: 3,
            text: 'D',
            page: 1,
            line: 1,
          ),
        ),
        isFalse,
      );
    });
  });
}
