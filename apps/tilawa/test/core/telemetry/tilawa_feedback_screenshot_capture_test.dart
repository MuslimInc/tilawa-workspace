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
      final int nonBlankPixels = (await tester.runAsync<int>(
        () => _countNonBlankPixels(bytes),
      ))!;
      expect(nonBlankPixels, greaterThan(100));
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

    testWidgets('waitForScreenReady uses configured default frame count', (
      tester,
    ) async {
      TilawaFeedbackScreenshotCapture.readyFrameCount = 0;

      await tester.runAsync<void>(
        TilawaFeedbackScreenshotCapture.waitForScreenReady,
      );
    });

    testWidgets('waits for delayed route render before capturing', (
      tester,
    ) async {
      var showContent = false;

      await tester.pumpWidget(
        SentryWidget(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getLightTheme(
              primaryColor: AppColors.defaultPrimary,
            ),
            home: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Scaffold(
                  body: Center(
                    child: showContent
                        ? const ColoredBox(
                            color: Colors.blue,
                            child: SizedBox(width: 180, height: 100),
                          )
                        : TextButton(
                            onPressed: () => setState(() => showContent = true),
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
      final int nonBlankPixels = (await tester.runAsync<int>(
        () => _countNonBlankPixels(bytes!),
      ))!;
      expect(nonBlankPixels, greaterThan(100));
    });

    testWidgets('rejects mostly blank captures', (tester) async {
      await tester.pumpWidget(
        SentryWidget(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
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
          waitForReady: false,
          rejectBlankCaptures: true,
          maxAttempts: 1,
        ),
      );

      expect(bytes, isNull);
    });

    testWidgets('continues when boundary rendering times out', (tester) async {
      TilawaFeedbackScreenshotCapture.renderBoundaryOverride = (_) async =>
          throw StateError('Screenshot toImage timed out');
      await _pumpCaptureProbe(tester);

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(
          rejectBlankCaptures: false,
        ),
      );

      expect(bytes, isNull);
    });

    testWidgets('uses render override for test-safe attachments', (
      tester,
    ) async {
      final Uint8List pngBytes = Uint8List.fromList(<int>[1, 2, 3]);
      TilawaFeedbackScreenshotCapture.renderBoundaryOverride = (_) async =>
          pngBytes;
      await _pumpCaptureProbe(tester);

      final Uint8List? bytes = await tester.runAsync<Uint8List?>(
        () => TilawaFeedbackScreenshotCapture.capturePngBytes(
          rejectBlankCaptures: false,
        ),
      );
      final SentryAttachment? attachment =
          await TilawaFeedbackScreenshotCapture.captureAttachment(
            rejectBlankCaptures: false,
          );

      expect(bytes, same(pngBytes));
      expect(attachment, isNotNull);
      expect(attachment!.bytes, same(pngBytes));
    });

    test('returns attachment override when configured', () async {
      final SentryAttachment attachment = SentryAttachment.fromUint8List(
        Uint8List.fromList(<int>[4, 5, 6]),
        'override.png',
      );
      TilawaFeedbackScreenshotCapture.attachmentOverride = () async =>
          attachment;

      expect(
        await TilawaFeedbackScreenshotCapture.captureAttachment(),
        same(attachment),
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
        await tester.runAsync<bool>(
          () => TilawaFeedbackScreenshotCapture.isMostlyBlank(bytes!),
        ),
        isFalse,
      );
    });
  });
}
