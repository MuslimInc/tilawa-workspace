import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/color_picker/block_picker.dart';

void main() {
  group('BlockPicker', () {
    testWidgets('renders all available colors', (WidgetTester tester) async {
      final List<MaterialColor> colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) {},
              availableColors: colors,
            ),
          ),
        ),
      );

      // Expect to find 3 color items (Inkwells inside Material)
      // The default item builder uses specific implementation details, but we can search for something generic
      // or just assume if it pumps without error and we find some widgets it's good.
      // Better to check if we can find widgets with the specific colors.

      // The default layout uses GridView.count
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(3));
    });

    testWidgets('calls onColorChanged on tap', (WidgetTester tester) async {
      Color? selectedColor;
      final List<MaterialColor> colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) => selectedColor = color,
              availableColors: colors,
            ),
          ),
        ),
      );

      // Tap the second color (green)
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pump();

      expect(selectedColor, Colors.green);
    });

    testWidgets('works with useInShowDialog: false', (
      WidgetTester tester,
    ) async {
      Color? selectedColor;
      final List<MaterialColor> colors = [Colors.red, Colors.green];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockPicker(
              pickerColor: Colors.red,
              onColorChanged: (color) => selectedColor = color,
              availableColors: colors,
              useInShowDialog: false,
            ),
          ),
        ),
      );

      // Tap green
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pump();
      expect(selectedColor, Colors.green);
    });
  });

  group('MultipleChoiceBlockPicker', () {
    testWidgets('renders multiple choices', (WidgetTester tester) async {
      final List<MaterialColor> colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultipleChoiceBlockPicker(
              pickerColors: const [Colors.red],
              onColorsChanged: (colors) {},
              availableColors: colors,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(3));
      // Red should be selected (opacity 1 for Icon)
      // This is diving deep into implementation details, maybe just check rendering for now.
    });

    testWidgets('toggles selection on tap', (WidgetTester tester) async {
      List<Color> currentColors = [Colors.red];
      final List<MaterialColor> colors = [
        Colors.red,
        Colors.green,
        Colors.blue,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MultipleChoiceBlockPicker(
                  pickerColors: currentColors,
                  onColorsChanged: (colors) {
                    setState(() => currentColors = colors);
                  },
                  availableColors: colors,
                );
              },
            ),
          ),
        ),
      );

      // Tap green (add)
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pump();
      expect(currentColors, containsAll([Colors.red, Colors.green]));
      expect(currentColors.length, 2);

      // Tap red (remove)
      await tester.tap(find.byType(InkWell).at(0));
      await tester.pump();
      expect(currentColors, equals([Colors.green]));
    });
  });
}
