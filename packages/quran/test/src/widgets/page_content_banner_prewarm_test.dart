import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/widgets/surah_header_banner.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid 1×1 transparent PNG (identical to flutter_test_config.dart).
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

/// Registers a mock asset handler that serves [_k1x1TransparentPng] for every
/// asset lookup. When [slowImage] is true and a [gate] completer is provided,
/// `mainframe.png` delivery is blocked until the gate is completed — allowing
/// tests to assert widget state before and after the image bytes arrive.
void _registerFakeAssets({bool slowImage = false, Completer<void>? gate}) {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    // The asset manifest uses a binary (non-UTF-8) codec. Attempting to
    // decode it as a string would throw a FormatException and corrupt the
    // manifest lookup. Pass through any non-decodable message to the real
    // handler so the framework can resolve its own metadata.
    late final String key;
    try {
      key = utf8.decode(message!.buffer.asUint8List());
    } catch (_) {
      return null; // Let the real handler deal with binary-codec messages.
    }

    if (key == 'AssetManifest.bin') {
      return _kEmptyAssetManifestBin;
    }

    // Only intercept image asset requests; forward everything else.
    if (!key.endsWith('.png') &&
        !key.endsWith('.jpg') &&
        !key.endsWith('.jpeg') &&
        !key.endsWith('.webp')) {
      return null;
    }

    if (slowImage && gate != null && key.endsWith('mainframe.png')) {
      await gate.future;
    }
    return ByteData.sublistView(_k1x1TransparentPng);
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    // Clear the Flutter image cache between tests so each test starts with an
    // empty cache — the key precondition that reproduces the initial-load bug.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  // -------------------------------------------------------------------------
  // 1. Image cache pre-warming contract
  // -------------------------------------------------------------------------
  group('Banner image pre-warming — image cache state', () {
    testWidgets(
      'image cache is empty before any SurahHeaderBanner is rendered',
      (WidgetTester tester) async {
        _registerFakeAssets();
        expect(PaintingBinding.instance.imageCache.currentSize, 0);
      },
    );

    testWidgets(
      'banner image is in cache after SurahHeaderBanner first pumpAndSettle',
      (WidgetTester tester) async {
        _registerFakeAssets();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderBanner(
                surahNumber: 18,
                lineHeight: 40,
                viewportWidth: 360,
                viewportHeight: 800,
                isLandscape: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(PaintingBinding.instance.imageCache.currentSize, greaterThan(0));
      },
    );

    testWidgets(
      'banner ImageStream resolve completes without a host widget tree',
      (WidgetTester tester) async {
        _registerFakeAssets();

        const imageProvider = AssetImage(
          'assets/mainframe.png',
          package: 'quran',
        );

        var didComplete = false;
        final completer = Completer<void>();

        await tester.runAsync(() async {
          const config = ImageConfiguration(devicePixelRatio: 1.0);
          final ImageStream stream = imageProvider.resolve(config);
          late final ImageStreamListener listener;
          listener = ImageStreamListener(
            (_, _) {
              didComplete = true;
              if (!completer.isCompleted) completer.complete();
              stream.removeListener(listener);
            },
            onError: (_, _) {
              didComplete = true;
              if (!completer.isCompleted) completer.complete();
              stream.removeListener(listener);
            },
          );
          stream.addListener(listener);
          await completer.future;
        });

        expect(didComplete, isTrue);
      },
    );
  });

  // -------------------------------------------------------------------------
  // 2. First-frame Image widget presence (reproduces the original bug)
  // -------------------------------------------------------------------------
  group('SurahHeaderBanner — first-frame Image widget presence', () {
    testWidgets(
      'Image widget is present in tree on the first pump (no double-pump required)',
      (WidgetTester tester) async {
        _registerFakeAssets();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderBanner(
                surahNumber: 18,
                lineHeight: 40,
                viewportWidth: 360,
                viewportHeight: 800,
                isLandscape: false,
              ),
            ),
          ),
        );

        // Single pump only: the Image widget must be in the tree on the first
        // frame, not just after image bytes have decoded. This directly tests
        // the observable contract of the pre-warming fix — the SnapshotController
        // captures a fully painted frame because the Image widget exists.
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      'Image widget remains present and error-free after pumpAndSettle',
      (WidgetTester tester) async {
        _registerFakeAssets();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderBanner(
                surahNumber: 18,
                lineHeight: 40,
                viewportWidth: 360,
                viewportHeight: 800,
                isLandscape: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
      },
    );

    testWidgets('Image widget is present when a ColorFilter is applied', (
      WidgetTester tester,
    ) async {
      _registerFakeAssets();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderBanner(
              surahNumber: 1,
              lineHeight: 40,
              viewportWidth: 360,
              viewportHeight: 800,
              isLandscape: false,
              headerImageFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
      'Image widget is present for boundary surah numbers 1 and 114',
      (WidgetTester tester) async {
        _registerFakeAssets();

        for (final surahNumber in <int>[1, 114]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SurahHeaderBanner(
                  surahNumber: surahNumber,
                  lineHeight: 40,
                  viewportWidth: 360,
                  viewportHeight: 800,
                  isLandscape: false,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(Image),
            findsOneWidget,
            reason: 'Image should be present for surah $surahNumber',
          );
        }
      },
    );
  });

  // -------------------------------------------------------------------------
  // 3. Slow image load
  // -------------------------------------------------------------------------
  group('Banner image pre-warming — slow image load', () {
    testWidgets('Image widget is in tree before image bytes have arrived', (
      WidgetTester tester,
    ) async {
      // Gate is never opened during the assertion — simulates a stalled asset.
      final gate = Completer<void>();
      _registerFakeAssets(slowImage: true, gate: gate);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderBanner(
              surahNumber: 18,
              lineHeight: 40,
              viewportWidth: 0,
              viewportHeight: 0,
              isLandscape: false,
            ),
          ),
        ),
      );

      // Intentionally no pumpAndSettle — image bytes not delivered yet.
      // The Image widget must already be in the tree because SurahHeaderBanner
      // declares it unconditionally; the fix ensures it is not conditionally
      // removed or replaced by a placeholder.
      expect(find.byType(Image), findsOneWidget);

      // Unblock to avoid async leaks after the test ends.
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Image widget is present and error-free after delayed decode completes',
      (WidgetTester tester) async {
        final gate = Completer<void>();
        _registerFakeAssets(slowImage: true, gate: gate);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderBanner(
                surahNumber: 18,
                lineHeight: 40,
                viewportWidth: 0,
                viewportHeight: 0,
                isLandscape: false,
              ),
            ),
          ),
        );

        expect(find.byType(Image), findsOneWidget);

        gate.complete();
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
      },
    );
  });

  // -------------------------------------------------------------------------
  // 4. Navigate away and return
  // -------------------------------------------------------------------------
  group('Banner image pre-warming — navigate away and return', () {
    testWidgets(
      'Image widget is present after pushing a second route and popping back',
      (WidgetTester tester) async {
        _registerFakeAssets();

        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            routes: {
              '/': (_) => const Scaffold(
                body: SurahHeaderBanner(
                  surahNumber: 18,
                  lineHeight: 40,
                  viewportWidth: 360,
                  viewportHeight: 800,
                  isLandscape: false,
                ),
              ),
              '/other': (_) => const Scaffold(body: SizedBox()),
            },
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);

        // Navigate away — banner is unmounted but its image stays in cache.
        unawaited(navigatorKey.currentState!.pushNamed('/other'));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsNothing);

        // Navigate back — banner must re-render from cache with no blank frame.
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
      },
    );

    testWidgets(
      'image cache retains banner asset across rebuilds (second render is a cache hit)',
      (WidgetTester tester) async {
        _registerFakeAssets();

        // First render — populates cache.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderBanner(
                surahNumber: 18,
                lineHeight: 40,
                viewportWidth: 360,
                viewportHeight: 800,
                isLandscape: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final int cacheSizeAfterFirstRender =
            PaintingBinding.instance.imageCache.currentSize;
        expect(cacheSizeAfterFirstRender, greaterThan(0));

        // Rebuild — simulates returning to the page.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderBanner(
                surahNumber: 18,
                lineHeight: 40,
                viewportWidth: 360,
                viewportHeight: 800,
                isLandscape: false,
              ),
            ),
          ),
        );
        // Single pump — image is already in cache, no decode delay expected.
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        // Cache must not have shrunk — the asset was not evicted.
        expect(
          PaintingBinding.instance.imageCache.currentSize,
          greaterThanOrEqualTo(cacheSizeAfterFirstRender),
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // 5. Edge cases
  // -------------------------------------------------------------------------
  group('Banner image pre-warming — edge cases', () {
    testWidgets('renders without crash when lineHeight is zero', (
      WidgetTester tester,
    ) async {
      _registerFakeAssets();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderBanner(
              surahNumber: 18,
              lineHeight: 0,
              viewportWidth: 360,
              viewportHeight: 800,
              isLandscape: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SurahHeaderBanner), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('renders without crash when headerTextColor is null', (
      WidgetTester tester,
    ) async {
      _registerFakeAssets();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderBanner(
              surahNumber: 18,
              lineHeight: 40,
              viewportWidth: 360,
              viewportHeight: 800,
              isLandscape: false,
              // ignore: avoid_redundant_argument_values
              headerTextColor: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('no ColorFiltered wrapper when headerImageFilter is null', (
      WidgetTester tester,
    ) async {
      _registerFakeAssets();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderBanner(
              surahNumber: 18,
              lineHeight: 40,
              viewportWidth: 360,
              viewportHeight: 800,
              isLandscape: false,
              // ignore: avoid_redundant_argument_values
              headerImageFilter: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNothing);
    });

    testWidgets(
      'multiple instances share a single cache entry for the banner asset',
      (WidgetTester tester) async {
        _registerFakeAssets();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  SurahHeaderBanner(
                    surahNumber: 1,
                    lineHeight: 40,
                    viewportWidth: 360,
                    viewportHeight: 800,
                    isLandscape: false,
                  ),
                  SurahHeaderBanner(
                    surahNumber: 18,
                    lineHeight: 40,
                    viewportWidth: 360,
                    viewportHeight: 800,
                    isLandscape: false,
                  ),
                  SurahHeaderBanner(
                    surahNumber: 114,
                    lineHeight: 40,
                    viewportWidth: 360,
                    viewportHeight: 800,
                    isLandscape: false,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All three instances decode the same asset — cache deduplicates to 1.
        expect(find.byType(Image), findsNWidgets(3));
        expect(PaintingBinding.instance.imageCache.currentSize, 1);
      },
    );
  });
}
