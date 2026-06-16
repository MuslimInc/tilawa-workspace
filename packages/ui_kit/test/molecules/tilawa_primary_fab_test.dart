import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaFabLocation', () {
    test('placement returns startFloat when offset is zero', () {
      final location = TilawaFabLocation.placement(TilawaFabPlacement.start);
      expect(
        location,
        FloatingActionButtonLocation.startFloat,
      );
    });

    test('placement applies bottom offset', () {
      const geometry = ScaffoldPrelayoutGeometry(
        scaffoldSize: Size(400, 800),
        bottomSheetSize: Size.zero,
        contentBottom: 800,
        contentTop: 0,
        floatingActionButtonSize: Size(56, 56),
        minInsets: EdgeInsets.zero,
        minViewPadding: EdgeInsets.zero,
        snackBarSize: Size.zero,
        materialBannerSize: Size.zero,
        textDirection: TextDirection.ltr,
      );

      final location = TilawaFabLocation.placement(
        TilawaFabPlacement.start,
        bottomOffset: 80,
      );
      final Offset offset = location.getOffset(geometry);
      final Offset base = FloatingActionButtonLocation.startFloat.getOffset(
        geometry,
      );

      expect(offset.dx, base.dx);
      expect(offset.dy, 800 - 56 - 80);
    });
  });

  group('TilawaPrimaryFab', () {
    testWidgets('invokes onPressed', (WidgetTester tester) async {
      var tapped = false;
      final ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF219653),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: colorScheme,
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(colorScheme: colorScheme),
            ],
          ),
          home: Scaffold(
            floatingActionButton: TilawaPrimaryFab(
              icon: Icons.add,
              heroTag: 'test_fab',
              semanticLabel: 'Create playlist',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.backgroundColor, colorScheme.primary);
      expect(fab.foregroundColor, colorScheme.onPrimary);
      expect(find.bySemanticsLabel('Create playlist'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
