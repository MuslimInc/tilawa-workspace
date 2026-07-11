import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart';
import 'package:quran_image/quran_image_page.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'quran_image_test_bootstrap.dart';

/// Standard phone viewport (iPhone 14 class).
const _phoneViewport = Size(390, 844);

/// Zebra MC93-class narrow Android handheld — matches Tilawa `narrowPhone` tests.
const _mc93Viewport = Size(360, 640);

const _goldenViewports = <({String label, Size size})>[
  (label: '390x844', size: _phoneViewport),
  (label: '360x640', size: _mc93Viewport),
];

Widget wrapQuranImageGoldenTestApp(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    locale: const Locale('en'),
    localizationsDelegates: QuranImageLocalizations.localizationsDelegates,
    supportedLocales: QuranImageLocalizations.supportedLocales,
    home: home,
  );
}

Future<void> pumpQuranImagePageGolden(
  WidgetTester tester, {
  required int pageNumber,
  required Size logicalSize,
}) async {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    wrapQuranImageGoldenTestApp(
      MediaQuery(
        data: MediaQueryData(size: logicalSize),
        child: Scaffold(
          body: QuranImagePage(pageNumber: pageNumber),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

String goldenPath({required int pageNumber, required String viewportLabel}) {
  return 'goldens/quran_image_page_${pageNumber}_$viewportLabel.png';
}

void main() {
  late Directory tempDirectory;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() async {
    tempDirectory = await bootstrapQuranImagePageTest(
      pageNumbers: const [1, 2],
      visiblePlaceholders: true,
    );
  });

  tearDown(() async {
    await tearDownQuranImageTest(tempDirectory);
  });

  group('QuranImagePage goldens', () {
    for (final viewport in _goldenViewports) {
      testWidgets('page 1 Al-Fatihah (${viewport.label})', (tester) async {
        await pumpQuranImagePageGolden(
          tester,
          pageNumber: 1,
          logicalSize: viewport.size,
        );

        await expectLater(
          find.byType(QuranImagePage),
          matchesGoldenFile(
            goldenPath(pageNumber: 1, viewportLabel: viewport.label),
          ),
        );
      });

      testWidgets('page 2 Al-Baqarah start (${viewport.label})', (
        tester,
      ) async {
        await pumpQuranImagePageGolden(
          tester,
          pageNumber: 2,
          logicalSize: viewport.size,
        );

        await expectLater(
          find.byType(QuranImagePage),
          matchesGoldenFile(
            goldenPath(pageNumber: 2, viewportLabel: viewport.label),
          ),
        );
      });
    }
  });
}
