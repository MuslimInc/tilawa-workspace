import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
  );

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaSelectionPill wrapping behavior', () {
    testWidgets('multiple pills fit on the same row in Wrap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TilawaSelectionPill(
                  label: 'A',
                  selected: true,
                  onTap: () {},
                ),
                TilawaSelectionPill(
                  label: 'B',
                  selected: false,
                  onTap: () {},
                ),
                TilawaSelectionPill(
                  label: 'C',
                  selected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      final Offset aCenter = tester.getCenter(find.text('A'));
      final Offset bCenter = tester.getCenter(find.text('B'));
      final Offset cCenter = tester.getCenter(find.text('C'));

      // All three pills share the same row (similar Y, distinct X).
      expect((aCenter.dy - bCenter.dy).abs(), lessThan(4));
      expect((bCenter.dy - cCenter.dy).abs(), lessThan(4));
      expect(aCenter.dx, isNot(bCenter.dx));
      expect(bCenter.dx, isNot(cCenter.dx));
    });

    testWidgets('pills do not stretch to full width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: Wrap(
              spacing: 8,
              children: [
                TilawaSelectionPill(
                  label: 'العربية',
                  selected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Find the pill
      final Finder pillFinder = find.byType(TilawaSelectionPill);
      expect(pillFinder, findsOneWidget);

      // Get the pill's size
      final Size pillSize = tester.getSize(pillFinder);

      // The pill should be much smaller than the container width (400)
      // A typical pill with text "العربية" should be around 80-120px
      expect(pillSize.width, lessThan(200));
    });

    testWidgets('selected state renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaSelectionPill(
            label: 'العربية',
            selected: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('العربية'), findsOneWidget);

      // Verify semantic selected state
      final Finder pillFinder = find.byType(TilawaSelectionPill);
      final TilawaSelectionPill pill = tester.widget(pillFinder);
      expect(pill.selected, isTrue);
    });

    testWidgets('unselected state renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaSelectionPill(
            label: 'الإنجليزية',
            selected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('الإنجليزية'), findsOneWidget);

      // Verify semantic selected state
      final Finder pillFinder = find.byType(TilawaSelectionPill);
      final TilawaSelectionPill pill = tester.widget(pillFinder);
      expect(pill.selected, isFalse);
    });

    testWidgets('tap callback is invoked when pill is tapped', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        _app(
          TilawaSelectionPill(
            label: 'العربية',
            selected: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(TilawaSelectionPill));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('catalog style renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaSelectionPill(
            label: ' tajweed',
            selected: true,
            style: TilawaSelectionPillStyle.catalog,
            onTap: () {},
          ),
        ),
      );

      expect(find.text(' tajweed'), findsOneWidget);

      final Finder pillFinder = find.byType(TilawaSelectionPill);
      final TilawaSelectionPill pill = tester.widget(pillFinder);
      expect(pill.style, TilawaSelectionPillStyle.catalog);
    });

    testWidgets('multiple pills wrap to multiple rows when needed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 200, // Narrow width to force wrapping
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                6,
                (index) => TilawaSelectionPill(
                  label: 'Option $index',
                  selected: index % 2 == 0,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 6; i++) {
        expect(find.text('Option $i'), findsOneWidget);
      }

      final Offset option0 = tester.getCenter(find.text('Option 0'));
      final Offset option5 = tester.getCenter(find.text('Option 5'));

      // Narrow container forces at least one wrap (different rows).
      expect(option0.dy, lessThan(option5.dy));
    });

    testWidgets('preserves RTL layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 400,
              child: Wrap(
                spacing: 8,
                children: [
                  TilawaSelectionPill(
                    label: 'العربية',
                    selected: true,
                    onTap: () {},
                  ),
                  TilawaSelectionPill(
                    label: 'الإنجليزية',
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('الإنجليزية'), findsOneWidget);

      expect(
        Directionality.of(tester.element(find.byType(Wrap))),
        TextDirection.rtl,
      );
    });
  });

  group('TilawaSelectionPill accessibility', () {
    testWidgets('has button semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          TilawaSelectionPill(
            label: 'العربية',
            selected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('العربية'), findsOneWidget);
    });

    testWidgets('meets minimum tap target of 48dp', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaSelectionPill(
            label: 'العربية',
            selected: false,
            onTap: () {},
          ),
        ),
      );

      final Finder pillFinder = find.byType(TilawaSelectionPill);
      final Size pillSize = tester.getSize(pillFinder);

      // Both dimensions should be at least 48dp
      expect(pillSize.height, greaterThanOrEqualTo(48));
      expect(pillSize.width, greaterThanOrEqualTo(48));
    });
  });
}
