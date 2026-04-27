import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// NOTE: To get pixel-perfect rendering of the Quran typography in tests,
// you must be sure to call await preloadFonts() or use a library like golden_toolkit
// that automatically handles font loading and asynchronous image rendering.

void main() {
  group(
    'Quran Pixel Validation Capture',
    () {
      const devices = <String, Size>{
        'iPhoneSE': Size(320, 568),
        'iPhone15Pro': Size(393, 852),
        'iPadMini': Size(768, 1024),
      };

      for (final device in devices.entries) {
        testWidgets('Capture Quran Page 207 on ${device.key}', (
          WidgetTester tester,
        ) async {
          // 1. Set the physical size to mirror the specific device
          tester.view.physicalSize = device.value;
          tester.view.devicePixelRatio = 1.0;

          // 2. Build the widget under test.
          // Replace this Container with the actual QuranReaderScreen or QuranPageView
          // loaded with proper dependencies via your DI/AppRouter.
          final widgetUnderTest = MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Replace with QuranPageView for Page 207',
                  style: const TextStyle(fontFamily: 'QCF4001_X-Regular'),
                ),
              ),
            ),
          );

          await tester.pumpWidget(widgetUnderTest);
          await tester.pumpAndSettle();

          // 3. Dump the screenshot. We point it into the screenshots folder
          // so `tools/quran_validation_suite.sh` can pick it up.
          // NOTE: ensure that you have standard ayah app target screenshots
          // named ayah_app_page_207_${device.key}.png
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../../../screenshots/tilawa_page_207_${device.key}.png',
            ),
          );

          // Reset
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      }
    },
    skip:
        'Placeholder golden harness pending real QuranPageView baseline images.',
  );
}
