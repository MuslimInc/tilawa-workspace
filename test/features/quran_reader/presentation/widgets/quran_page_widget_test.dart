import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_page_widget.dart';

void main() {
  group('QuranPageWidget (Image-Based)', () {
    testWidgets('renders 15 lines of images for a given page', (tester) async {
      // Data Setup: Page 1 (Al-Fatiha)
      final ayahs = [
        const PageAyahInfo(
          surahNumber: 1,
          ayahNumber: 1,
          surahName: 'الفاتحة',
          surahNameEnglish: 'Al-Fatiha',
          text: 'Text is not used for rendering',
        ),
      ];

      final page = QuranPageEntity(
        pageNumber: 1,
        ayahs: ayahs,
        juz: 1,
        hizb: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuranPageWidget(page: page)),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify 15 Images for the lines
      // We look for Images that are asset images with the pattern:
      // assets/quranlines/p1_X.png
      for (var i = 1; i <= 15; i++) {
        final Finder lineImageFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/quranlines/p1_$i.png',
        );
        expect(
          lineImageFinder,
          findsOneWidget,
          reason: 'Line $i should be rendered',
        );
      }

      // 2. Verify Page Footer
      // Hizb 1 | 1
      expect(find.text('Hizb 1 | 1'), findsOneWidget);
    });

    testWidgets('renders correct image paths for Page 604', (tester) async {
      const page = QuranPageEntity(
        pageNumber: 604,
        ayahs: [],
        juz: 30,
        hizb: 60,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: QuranPageWidget(page: page)),
        ),
      );
      await tester.pumpAndSettle();

      // Verify a sample line for page 604
      final Finder line1Finder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/quranlines/p604_1.png',
      );
      expect(line1Finder, findsOneWidget);
    });
  });
}
