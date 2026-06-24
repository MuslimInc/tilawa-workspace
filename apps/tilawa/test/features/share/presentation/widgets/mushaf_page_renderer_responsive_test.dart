import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/share/presentation/utils/share_feature_flags.dart';
import 'package:tilawa/features/share/presentation/utils/video_page_specs.dart';
import 'package:tilawa/features/share/presentation/widgets/mushaf_page_renderer.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
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

Widget _buildRendererHarness({
  required int pageNumber,
  int? surahNumber,
  int fromAyah = 1,
  int toAyah = 1,
}) {
  final MushafPageRenderer renderer = MushafPageRenderer.defaultRenderer();
  final List<PageSurahEntry> pageEntries = getPageData(pageNumber);
  final int resolvedSurahNumber =
      surahNumber ?? (pageEntries.isNotEmpty ? pageEntries.first.surah : 1);

  return MaterialApp(
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      backgroundColor: const Color(0xFFFFF8ED),
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: RepaintBoundary(
            child: Builder(
              builder: (BuildContext context) {
                return renderer.build(
                  context: context,
                  pageSpec: VideoPageSpec(
                    pageNumber: pageNumber,
                    fromAyah: fromAyah,
                    toAyah: toAyah,
                  ),
                  surahNumber: resolvedSurahNumber,
                  verseBackgroundColor: (_, _) => null,
                  verseTextColor: (_, _) => null,
                  textColor: const Color(0xFF2E2116),
                  pageBackgroundColor: const Color(0xFFFFF8ED),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

List<int> _preparedVerses(PageContent pageContent) {
  final preparedPage = pageContent.preparedPage;
  if (preparedPage == null) return const <int>[];

  return preparedPage.blocks
      .whereType<PreparedTextBlock>()
      .expand((block) => block.metadata)
      .map((metadata) => metadata.verse)
      .toSet()
      .toList(growable: false)
    ..sort();
}

List<String> _drainFrameworkExceptions(WidgetTester tester) {
  final List<String> exceptions = <String>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception.toString());
  }
  return exceptions;
}

// Sub-pixel overflow can come from font ascent/descent rounding. The page
// is rendered inside a ClipRect so any overflow under this threshold is
// not visible to the user — fail only when the visible layout is broken.
const double _overflowToleranceLogicalPx = 8.0;

final RegExp _overflowPattern = RegExp(r'overflowed by ([\d.]+) pixels');

({List<String> blocking, List<String> tolerated}) _classifyOverflows(
  List<String> exceptions,
) {
  final blocking = <String>[];
  final tolerated = <String>[];
  for (final String message in exceptions) {
    final Match? match = _overflowPattern.firstMatch(message);
    if (match == null) {
      blocking.add(message);
      continue;
    }
    final double pixels =
        double.tryParse(match.group(1) ?? '') ?? double.infinity;
    if (pixels <= _overflowToleranceLogicalPx) {
      tolerated.add(message);
    } else {
      blocking.add(message);
    }
  }
  return (blocking: blocking, tolerated: tolerated);
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
    testWidgets('crops selected text metadata under the reel composer flag', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = _devices['iPhone15Pro']!;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const pageNumber = 3;
      quranQcfLocator<QuranFontService>().debugMarkFontLoaded(pageNumber);

      await tester.pumpWidget(
        _buildRendererHarness(
          pageNumber: pageNumber,
          surahNumber: 2,
          fromAyah: 6,
          toAyah: 8,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final pageContent = tester.widget<PageContent>(find.byType(PageContent));
      final verses = _preparedVerses(pageContent);

      expect(verses, isNotEmpty);
      if (kReelComposerV2) {
        expect(verses.every((verse) => verse >= 6 && verse <= 8), isTrue);
      } else {
        expect(verses.any((verse) => verse < 6 || verse > 8), isTrue);
      }

      final classified = _classifyOverflows(_drainFrameworkExceptions(tester));
      expect(classified.blocking, isEmpty);
    });

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
            final classified = _classifyOverflows(frameworkExceptions);

            expect(
              classified.blocking,
              isEmpty,
              reason:
                  'Framework exceptions on ${device.key} page $pageNumber: '
                  '${classified.blocking.join('\n')}',
            );

            expect(find.byType(PageContent), findsOneWidget);
          },
        );
      }
    }
  });
}
