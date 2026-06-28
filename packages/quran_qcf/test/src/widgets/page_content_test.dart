import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:quran_qcf/src/presentation/widgets/page_metadata_strip.dart';
import 'package:quran_qcf/src/presentation/widgets/quran_page_painter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
  "h1": {"text": "SURAH_HEADER", "surah": "5", "ayah": "0", "word": "0"},
  "w1": {"text": "AB", "surah": "5", "ayah": "1", "word": "1"},
  "w2": {"text": "CD", "surah": "5", "ayah": "2", "word": "1"}
}
''';

const String _fakePageIndexJson = '''
{
  "10": {
    "1": ["h1"],
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

    if (key == 'packages/quran_qcf/assets/quran_fonts/qpc-v4.json') {
      final bytes = Uint8List.fromList(utf8.encode(_fakeQpcV4Json));
      return ByteData.sublistView(bytes);
    }

    if (key == 'packages/quran_qcf/assets/quran_fonts/quran_page_index.json') {
      final bytes = Uint8List.fromList(utf8.encode(_fakePageIndexJson));
      return ByteData.sublistView(bytes);
    }

    if (key.endsWith('sura_header_banner.png')) {
      return ByteData.sublistView(_k1x1TransparentPng);
    }

    return null;
  });
}

late MushafService mushafService;
late QuranFontService fontService;
late QuranPagePreparationService preparationService;
late PageSnapshotService snapshotService;
late IdleScheduler idleScheduler;

Widget _buildPageContent({
  required PreparedQuranPage preparedPage,
  ValueNotifier<int>? currentPage,
  ValueChanged<int>? onSurahSelected,
  VoidCallback? onShowIndex,
}) {
  return MaterialApp(
    theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
    home: Scaffold(
      body: PageContent(
        pageNumber: 10,
        preparedPage: preparedPage,
        textColor: Colors.black,
        pageBackgroundColor: Colors.white,
        currentPageListenable: currentPage ?? ValueNotifier<int>(10),
        showOverlaysListenable: ValueNotifier<bool>(true),
        surahNameBuilder: (surahNumber) => 'Surah $surahNumber',
        onSurahSelected: onSurahSelected,
        onShowIndex: onShowIndex,
        mushafService: mushafService,
        pageSnapshotService: snapshotService,
      ),
    ),
  );
}

Future<PreparedQuranPage> _preparePageContent(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
  });

  await tester.runAsync(() async {
    await mushafService.ensureLoaded();
  });

  late final PreparedQuranPage preparedPage;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final Size viewportSize = MediaQuery.sizeOf(context);
            final QuranLayoutMetrics metrics = StandardQuranLayoutStrategy()
                .calculateMetrics(
                  context,
                  BoxConstraints(
                    maxWidth: viewportSize.width,
                    maxHeight: viewportSize.height,
                  ),
                  10,
                  mushafService,
                );
            preparedPage = preparationService.preparePage(
              pageNumber: 10,
              metrics: metrics,
              viewportWidth: viewportSize.width,
              textColor: Colors.black,
              mushafService: mushafService,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return preparedPage;
}

Future<void> _pumpPageContent(
  WidgetTester tester, {
  ValueNotifier<int>? currentPage,
  ValueChanged<int>? onSurahSelected,
  VoidCallback? onShowIndex,
}) async {
  final PreparedQuranPage preparedPage = await _preparePageContent(tester);
  await tester.pumpWidget(
    _buildPageContent(
      preparedPage: preparedPage,
      currentPage: currentPage,
      onSurahSelected: onSurahSelected,
      onShowIndex: onShowIndex,
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_registerFakeAssets);
  setUp(() {
    mushafService = MushafService();
    idleScheduler = IdleScheduler();
    fontService = QuranFontService(
      mushafService: mushafService,
      idleScheduler: idleScheduler,
    );
    preparationService = QuranPagePreparationService();
    snapshotService = PageSnapshotService(idleScheduler: idleScheduler);
  });

  testWidgets(
    'PageContent renders prepared Quran page painter once the page font is ready',
    (WidgetTester tester) async {
      fontService.debugMarkFontLoaded(10);

      await _pumpPageContent(tester);

      expect(find.byType(QuranPagePainter), findsOneWidget);
      expect(find.byType(PageMetadataStrip), findsOneWidget);
    },
  );

  testWidgets(
    'PageContent reconnects the surah banner and metadata strip actions',
    (WidgetTester tester) async {
      int? selectedSurah;
      var showIndexCalls = 0;
      fontService.debugMarkFontLoaded(10);

      await _pumpPageContent(
        tester,
        onSurahSelected: (surahNumber) {
          selectedSurah = surahNumber;
        },
        onShowIndex: () {
          showIndexCalls++;
        },
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
