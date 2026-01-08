import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_reader_bottom_bar.dart';

void main() {
  group('QuranReaderBottomBar', () {
    testWidgets('should display current page number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderBottomBar(
              currentPage: 42,
              totalPages: 604,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('should display grid view icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderBottomBar(
              currentPage: 1,
              totalPages: 604,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });

    testWidgets('should display sync icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderBottomBar(
              currentPage: 1,
              totalPages: 604,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });

    testWidgets('should display slider', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderBottomBar(
              currentPage: 1,
              totalPages: 604,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should call onPageChanged when slider value changes', (
      WidgetTester tester,
    ) async {
      var changedPage = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderBottomBar(
              currentPage: 1,
              totalPages: 604,
              onPageChanged: (page) => changedPage = page,
            ),
          ),
        ),
      );

      // Find slider and drag it
      final Finder slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Interact with slider
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      // onPageChanged should have been called
      expect(changedPage, greaterThan(0));
    });

    testWidgets('should clamp page value within valid range', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderBottomBar(
              currentPage: 605, // Invalid, should clamp
              totalPages: 604,
              onPageChanged: (_) {},
            ),
          ),
        ),
      );

      // Should not crash
      expect(find.byType(QuranReaderBottomBar), findsOneWidget);
    });
  });
}
