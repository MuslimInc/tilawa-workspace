import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/share/presentation/widgets/share_poster_renderer.dart';
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

List<String> _drainFrameworkExceptions(WidgetTester tester) {
  final List<String> exceptions = <String>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception.toString());
  }
  return exceptions;
}

Widget _buildHarness({int surahNumber = 1, int fromAyah = 1, int toAyah = 7}) {
  return MaterialApp(
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    home: Scaffold(
      backgroundColor: const Color(0xFFFFF9F1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 84),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 360,
                  height: 520,
                  child: SharePosterRenderer(
                    surahNumber: surahNumber,
                    fromAyah: fromAyah,
                    toAyah: toAyah,
                    reciterName: 'Test Reciter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 220),
          ],
        ),
      ),
    ),
  );
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

  testWidgets('SharePosterRenderer avoids preview overflow on compact layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final int pageNumber = getPageNumber(1, 1);
    quranQcfLocator<QuranFontService>().debugMarkFontLoaded(pageNumber);

    await tester.pumpWidget(_buildHarness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final List<String> exceptions = _drainFrameworkExceptions(tester);
    final List<String> overflowExceptions = exceptions
        .where((message) => message.contains('A RenderFlex overflowed'))
        .toList();

    expect(
      overflowExceptions,
      isEmpty,
      reason:
          'Unexpected poster preview overflow: ${overflowExceptions.join('\n')}',
    );
    expect(find.byType(SharePosterRenderer), findsOneWidget);
    expect(find.byType(PageContent), findsOneWidget);
    expect(find.byType(SurahHeaderBanner), findsOneWidget);
    expect(find.byType(OverflowBox), findsNothing);
  });

  testWidgets('SharePosterRenderer top-composes a mid-page selection', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final int pageNumber = getPageNumber(41, 34);
    quranQcfLocator<QuranFontService>().debugMarkFontLoaded(pageNumber);

    await tester.pumpWidget(
      _buildHarness(surahNumber: 41, fromAyah: 34, toAyah: 35),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final List<String> exceptions = _drainFrameworkExceptions(tester);
    final List<String> overflowExceptions = exceptions
        .where((message) => message.contains('A RenderFlex overflowed'))
        .toList();

    expect(
      overflowExceptions,
      isEmpty,
      reason:
          'Unexpected poster preview overflow: ${overflowExceptions.join('\n')}',
    );
    expect(find.byType(SurahHeaderBanner), findsOneWidget);
    expect(find.byType(OverflowBox), findsNothing);
  });
}
