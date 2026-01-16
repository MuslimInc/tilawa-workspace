import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/color_picker/material_picker.dart';

void main() {
  group('MaterialPicker', () {
    testWidgets('renders correctly in portrait mode', (
      WidgetTester tester,
    ) async {
      // Set surface size to portrait
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
            ),
          ),
        ),
      );

      // Should find ListViews for main colors and shades
      expect(find.byType(ListView), findsNWidgets(2));

      // In portrait, it returns a Column with a SizedBox of width 350, height 500
      // containing a Row
      // Actually checking if the top level container structure matches logic matches
      // the isPortrait check
    });

    testWidgets('renders correctly in landscape mode', (
      WidgetTester tester,
    ) async {
      // Set surface size to landscape
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsNWidgets(2));
      // In landscape, we expect different layout structure
    });

    testWidgets('selects primary color', (WidgetTester tester) async {
      Color? primaryColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
              onPrimaryChanged: (color) => primaryColor = color,
            ),
          ),
        ),
      );

      // Default is red. Let's tap something else, e.g. Pink (index 1)
      // The first ListView contains the primary colors.
      final Finder primaryList = find.byType(ListView).first;
      final Finder pinkFinder = find
          .descendant(of: primaryList, matching: find.byType(GestureDetector))
          .at(1);

      await tester.tap(pinkFinder);
      await tester.pump();

      expect(primaryColor, Colors.pink);
    });

    testWidgets('selects shade', (WidgetTester tester) async {
      Color? selectedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) => selectedColor = color,
            ),
          ),
        ),
      );

      // Shades are in the second ListView (or Expanded part)
      // Since red is default, shades of red are shown.
      // Let's tap a shade.
      final Finder shadesList = find.byType(ListView).last;
      final Finder shadeFinder = find
          .descendant(of: shadesList, matching: find.byType(GestureDetector))
          .at(2); // e.g. Red[200]

      await tester.tap(shadeFinder);
      await tester.pump();

      expect(selectedColor, isNotNull);
      expect(
        selectedColor,
        isNot(Colors.red),
      ); // precise value depends on index
    });

    testWidgets('handles Grey color shading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.grey,
              onColorChanged: (color) {},
            ),
          ),
        ),
      );

      // Find Grey in primary list and tap it (index 17 based on _colorTypes)
      final Finder primaryList = find.byType(ListView).first;

      final Finder greyItem = find.byWidgetPredicate((widget) {
        if (widget is AnimatedContainer && widget.decoration is BoxDecoration) {
          return (widget.decoration! as BoxDecoration).color == Colors.grey;
        }
        return false;
      });

      await tester.scrollUntilVisible(
        greyItem,
        500.0,
        scrollable: find.descendant(
          of: primaryList,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(greyItem);
      await tester.pumpAndSettle();

      // Check if shades list contains grey shades
      // We can check if we can tap a shade that is a grey shade
    });

    testWidgets('handles Black/White special case', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.black,
              onColorChanged: (color) {},
            ),
          ),
        ),
      );

      // Index 19 is Colors.black
      final Finder primaryList = find.byType(ListView).first;

      final Finder blackItem = find.byWidgetPredicate((widget) {
        if (widget is AnimatedContainer && widget.decoration is BoxDecoration) {
          return (widget.decoration! as BoxDecoration).color == Colors.black;
        }
        return false;
      });

      await tester.scrollUntilVisible(
        blackItem,
        500.0,
        scrollable: find.descendant(
          of: primaryList,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(blackItem);
      await tester.pumpAndSettle();

      // Should show black and white in shading list
      final Finder shadesList = find.byType(ListView).last;
      expect(
        find.descendant(of: shadesList, matching: find.byType(GestureDetector)),
        findsAtLeastNWidgets(2),
      );
    });

    testWidgets('renders with enableLabel=true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
              enableLabel: true,
            ),
          ),
        ),
      );
      // Wait for animations
      await tester.pumpAndSettle();

      // Should find text with shade values e.g. "50", "100"
      expect(
        find.text('50', findRichText: true),
        findsOneWidget,
      ); // Red[50] exists
    });

    testWidgets('Testing Dark Theme rendering (coverage)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Only verifying it crashes or not, and hitting those code paths
    });

    testWidgets('Testing Light Theme rendering (coverage)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: MaterialPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}
