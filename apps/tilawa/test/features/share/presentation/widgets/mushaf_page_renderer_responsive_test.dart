import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:quran_qcf/src/presentation/widgets/quran_page_painter.dart';
import 'package:tilawa/features/share/presentation/utils/video_page_specs.dart';
import 'package:tilawa/features/share/presentation/widgets/mushaf_page_renderer.dart';
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

const Map<String, Size> _devices = <String, Size>{
  'iPhoneSE': Size(320, 568),
  'iPhone15Pro': Size(393, 852),
  'iPadMini': Size(768, 1024),
};

const List<int> _pages = <int>[1, 207, 604];

Uint8List? _qpcV4Bytes;
Uint8List? _pageIndexBytes;

Future<void> _registerRealMushafAssets() async {
  _qpcV4Bytes ??= await _readRepoAssetBytes(const <String>[
    'packages/quran_qcf/assets/quran_fonts/qpc-v4.json',
    '../packages/quran_qcf/assets/quran_fonts/qpc-v4.json',
    '../../packages/quran_qcf/assets/quran_fonts/qpc-v4.json',
  ]);
  _pageIndexBytes ??= await _readRepoAssetBytes(const <String>[
    'packages/quran_qcf/assets/quran_fonts/quran_page_index.json',
    '../packages/quran_qcf/assets/quran_fonts/quran_page_index.json',
    '../../packages/quran_qcf/assets/quran_fonts/quran_page_index.json',
  ]);

  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    if (message == null) return null;

    final String key = utf8.decode(message.buffer.asUint8List());

    if (key == 'AssetManifest.bin') {
      return _kEmptyAssetManifestBin;
    }

    if (key == 'packages/quran_qcf/assets/quran_fonts/qpc-v4.json') {
      return ByteData.sublistView(_qpcV4Bytes!);
    }

    if (key == 'packages/quran_qcf/assets/quran_fonts/quran_page_index.json') {
      return ByteData.sublistView(_pageIndexBytes!);
    }

    if (key.endsWith('.png') ||
        key.endsWith('.jpg') ||
        key.endsWith('.jpeg') ||
        key.endsWith('.webp')) {
      return ByteData.sublistView(_k1x1TransparentPng);
    }

    return null;
  });
}

Future<Uint8List> _readRepoAssetBytes(List<String> candidates) async {
  for (final String candidate in candidates) {
    final File file = File(candidate);
    if (await file.exists()) {
      return file.readAsBytes();
    }
  }
  throw StateError(
    'Unable to locate asset file. Tried: ${candidates.join(', ')}',
  );
}

Widget _buildRendererHarness({required int pageNumber}) {
  final MushafPageRenderer renderer = MushafPageRenderer.defaultRenderer();
  final List<PageSurahEntry> pageEntries = getPageData(pageNumber);
  final int surahNumber = pageEntries.isNotEmpty ? pageEntries.first.surah : 1;

  return MaterialApp(
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    home: Scaffold(
      backgroundColor: const Color(0xFFFFF8ED),
      body: RepaintBoundary(
        child: Builder(
          builder: (BuildContext context) {
            return renderer.build(
              context: context,
              pageSpec: VideoPageSpec(
                pageNumber: pageNumber,
                fromAyah: 1,
                toAyah: 1,
              ),
              surahNumber: surahNumber,
              verseBackgroundColor: (_, _) => null,
              textColor: const Color(0xFF2E2116),
              pageBackgroundColor: const Color(0xFFFFF8ED),
            );
          },
        ),
      ),
    ),
  );
}

List<String> _drainFrameworkExceptions(WidgetTester tester) {
  final List<String> exceptions = <String>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception.toString());
  }
  return exceptions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _registerRealMushafAssets();
  });

  setUp(() async {
    await QuranQcfLocator.resetForTests();
    QuranQcfLocator.setup();
    await quranQcfLocator<MushafService>().ensureLoaded();
  });

  tearDown(() async {
    quranQcfLocator<QuranFontService>().debugResetForTests();
    await QuranQcfLocator.resetForTests();
  });

  group('QcfMushafPageRenderer responsive layout', () {
    for (final MapEntry<String, Size> device in _devices.entries) {
      for (final int pageNumber in _pages) {
        testWidgets(
          'renders page $pageNumber on ${device.key} without overflow',
          (WidgetTester tester) async {
            tester.view.physicalSize = device.value;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            quranQcfLocator<QuranFontService>().debugMarkFontLoaded(pageNumber);

            await tester.pumpWidget(
              _buildRendererHarness(pageNumber: pageNumber),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            final List<String> frameworkExceptions = _drainFrameworkExceptions(
              tester,
            );

            expect(
              frameworkExceptions,
              isEmpty,
              reason:
                  'Framework exceptions on ${device.key} page $pageNumber: '
                  '${frameworkExceptions.join('\n')}',
            );
            expect(
              frameworkExceptions.where(
                (String message) => message.contains('overflowed by'),
              ),
              isEmpty,
              reason:
                  'Overflow detected on ${device.key} page $pageNumber: '
                  '${frameworkExceptions.join('\n')}',
            );

            expect(find.byType(PageContent), findsOneWidget);
            expect(find.byType(QuranPagePainter), findsWidgets);
          },
        );
      }
    }
  });
}
