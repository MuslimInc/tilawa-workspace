import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_capture.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Future<int> _countNonBlankPixels(Uint8List pngBytes) async {
  final ui.Image image = await decodeImageFromList(pngBytes);
  try {
    final ByteData? rgba = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    expect(rgba, isNotNull);

    final Uint8List pixels = rgba!.buffer.asUint8List();
    var nonBlankPixels = 0;
    for (var index = 0; index < pixels.length; index += 4) {
      final int red = pixels[index];
      final int green = pixels[index + 1];
      final int blue = pixels[index + 2];
      if (red > 10 || green > 10 || blue > 10) {
        nonBlankPixels++;
      }
    }
    return nonBlankPixels;
  } finally {
    image.dispose();
  }
}

Future<void> _pumpCaptureProbe(WidgetTester tester) async {
  await tester.pumpWidget(
    SentryWidget(
      child: MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ColoredBox(
              color: Colors.green,
              child: SizedBox(
                width: 200,
                height: 120,
                child: Text('Tilawa screenshot probe'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TilawaFeedbackScreenshotCapture.resetTestConfiguration();
    TilawaFeedbackScreenshotCapture.readyFrameCount = 1;
    TilawaFeedbackScreenshotCapture.boundaryReadyFrames = 0;
    TilawaFeedbackScreenshotCapture.maxCaptureAttempts = 1;
  });

  tearDown(TilawaFeedbackScreenshotCapture.resetTestConfiguration);

  group('TilawaFeedbackScreenshotCapture', () {
    testWidgets('captures unmasked app content as PNG bytes', (tester) async {
      await _pumpCaptureProbe(tester);

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(),
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(1000));
      expect(await _countNonBlankPixels(bytes), greaterThan(100));
    });

    testWidgets('returns null when SentryScreenshotWidget is absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const Scaffold(body: Text('no sentry wrapper')),
        ),
      );
      await tester.pumpAndSettle();

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(),
      );

      expect(bytes, isNull);
    });

    testWidgets('waits for delayed route render before capturing', (
      tester,
    ) async {
      var showContent = false;

      await tester.pumpWidget(
        SentryWidget(
          child: MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            home: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: showContent
                        ? const ColoredBox(
                            color: Colors.blue,
                            child: SizedBox(width: 180, height: 100),
                          )
                        : TextButton(
                            onPressed: () => showContent = true,
                            child: const Text('reveal'),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('reveal'));
      await tester.pump();

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(
          waitForReady: true,
        ),
      );

      expect(bytes, isNotNull);
      expect(await _countNonBlankPixels(bytes!), greaterThan(100));
    });

    testWidgets('rejects mostly blank captures', (tester) async {
      await tester.pumpWidget(
        SentryWidget(
          child: MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            home: const Scaffold(
              backgroundColor: Colors.black,
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(
          waitForReady: true,
          rejectBlankCaptures: true,
          maxAttempts: 1,
        ),
      );

      expect(bytes, isNull);
    });

    testWidgets('isMostlyBlank flags near-black PNGs', (tester) async {
      await tester.pumpWidget(
        SentryWidget(
          child: MaterialApp(
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            home: const Scaffold(
              backgroundColor: Colors.black,
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(
          rejectBlankCaptures: false,
          maxAttempts: 1,
        ),
      );
      expect(bytes, isNotNull);

      expect(
        await TilawaFeedbackScreenshotCapture.isMostlyBlank(bytes!),
        isTrue,
      );
    });

    testWidgets('no black screenshot regression on colored content', (
      tester,
    ) async {
      await _pumpCaptureProbe(tester);

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(),
      );

      expect(bytes, isNotNull);
      expect(
        await TilawaFeedbackScreenshotCapture.isMostlyBlank(bytes!),
        isFalse,
      );
    });
  });
}
