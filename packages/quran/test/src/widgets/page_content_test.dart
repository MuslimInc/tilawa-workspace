import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/page_content.dart';
import 'package:quran/src/services/quran_data_service.dart';
import 'package:quran/src/widgets/page_metadata_strip.dart';
import 'package:quran/src/widgets/surah_header_banner.dart';

final Uint8List _k1x1TransparentPng = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x62,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE5,
  0x27,
  0xDE,
  0xFC,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

final ByteData _kEmptyAssetManifestBin = const StandardMessageCodec()
    .encodeMessage(<Object?, Object?>{})!;

const String _fakeQpcV4Json = '''
{
  "w1": {"text": "AB", "surah": "5", "ayah": "1", "word": "1"},
  "w2": {"text": "CD", "surah": "5", "ayah": "2", "word": "1"}
}
''';

const String _fakePageIndexJson = '''
{
  "10": {
    "4": ["w1", "w2"]
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

    if (key == 'AssetManifest.bin') {
      return _kEmptyAssetManifestBin;
    }

    if (key == 'packages/quran/assets/quran_fonts/qpc-v4.json') {
      final bytes = Uint8List.fromList(utf8.encode(_fakeQpcV4Json));
      return ByteData.sublistView(bytes);
    }

    if (key == 'packages/quran/assets/quran_fonts/quran_page_index.json') {
      final bytes = Uint8List.fromList(utf8.encode(_fakePageIndexJson));
      return ByteData.sublistView(bytes);
    }

    if (key.endsWith('mainframe.png')) {
      return ByteData.sublistView(_k1x1TransparentPng);
    }

    return null;
  });
}

Widget _buildPageContent({
  ValueNotifier<int>? currentPage,
  void Function(int surahNumber, int verseNumber)? onLongPress,
  void Function(int surahNumber, int verseNumber)? onLongPressUp,
  void Function(int surahNumber, int verseNumber)? onLongPressCancel,
  void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown,
  ValueChanged<int>? onSurahSelected,
  VoidCallback? onShowIndex,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PageContent(
        pageNumber: 10,
        textColor: Colors.black,
        pageBackgroundColor: Colors.white,
        currentPageListenable: currentPage ?? ValueNotifier<int>(10),
        surahNameBuilder: (surahNumber) => 'Surah $surahNumber',
        onLongPress: onLongPress,
        onLongPressUp: onLongPressUp,
        onLongPressCancel: onLongPressCancel,
        onLongPressDown: onLongPressDown,
        onSurahSelected: onSurahSelected,
        onShowIndex: onShowIndex,
      ),
    ),
  );
}

Future<void> _pumpPageContent(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
  });

  await tester.runAsync(() async {
    await QuranDataService.instance.ensureLoaded();
  });

  await tester.pumpWidget(widget);
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 300));
      return;
    }
  }

  fail('PageContent did not finish loading in the widget test.');
}

RichText _findVerseRichText(WidgetTester tester) {
  return tester.widgetList<RichText>(find.byType(RichText)).firstWhere((
    RichText richText,
  ) {
    final InlineSpan text = richText.text;
    if (text is! TextSpan) {
      return false;
    }
    final List<InlineSpan>? children = text.children;
    if (children == null) {
      return false;
    }
    final String joinedText = children.whereType<TextSpan>().map((span) {
      return span.text ?? '';
    }).join();
    return joinedText == 'AB\u200ACD';
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_registerFakeAssets);

  testWidgets(
    'PageContent keeps the thin space after the full first word and wires long-press callbacks',
    (WidgetTester tester) async {
      final events = <String>[];

      await _pumpPageContent(
        tester,
        _buildPageContent(
          onLongPress: (surahNumber, verseNumber) {
            events.add('press:$surahNumber:$verseNumber');
          },
          onLongPressUp: (surahNumber, verseNumber) {
            events.add('up:$surahNumber:$verseNumber');
          },
          onLongPressCancel: (surahNumber, verseNumber) {
            events.add('cancel:$surahNumber:$verseNumber');
          },
          onLongPressDown: (surahNumber, verseNumber, _) {
            events.add('start:$surahNumber:$verseNumber');
          },
        ),
      );

      final RichText verseRichText = _findVerseRichText(tester);
      final rootSpan = verseRichText.text as TextSpan;
      final List<TextSpan> spans = rootSpan.children!.cast<TextSpan>();

      expect(spans.map((span) => span.text).toList(), const <String?>[
        'A',
        'B',
        '\u200A',
        'C',
        'D',
      ]);
      expect(identical(spans[0].recognizer, spans[1].recognizer), isTrue);

      final firstWordRecognizer =
          spans.first.recognizer! as LongPressGestureRecognizer;
      firstWordRecognizer.onLongPressStart?.call(const LongPressStartDetails());
      firstWordRecognizer.onLongPress?.call();
      firstWordRecognizer.onLongPressUp?.call();
      firstWordRecognizer.onLongPressCancel?.call();

      expect(events, const <String>[
        'start:5:1',
        'press:5:1',
        'up:5:1',
        'cancel:5:1',
      ]);
    },
  );

  testWidgets(
    'PageContent reconnects the surah banner and metadata strip actions',
    (WidgetTester tester) async {
      int? selectedSurah;
      var showIndexCalls = 0;

      await _pumpPageContent(
        tester,
        _buildPageContent(
          onSurahSelected: (surahNumber) {
            selectedSurah = surahNumber;
          },
          onShowIndex: () {
            showIndexCalls++;
          },
        ),
      );

      await tester.tap(find.byType(SurahHeaderBanner));
      await tester.pump();
      await tester.tap(find.byType(PageMetadataStrip));
      await tester.pump();

      expect(selectedSurah, 5);
      expect(showIndexCalls, 1);
    },
  );
}
