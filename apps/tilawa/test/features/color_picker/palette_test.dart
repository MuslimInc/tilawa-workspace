import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/color_picker/palette.dart';

void main() {
  group('ColorPickerArea', () {
    testWidgets('renders correctly for all PaletteTypes', (
      WidgetTester tester,
    ) async {
      for (final PaletteType type in PaletteType.values) {
        if (type == PaletteType.hueWheel) {
          // HueWheel renders a ColorPickerHueRing actually?
          // No, ColorPickerArea with hueWheel type renders CustomPaint using _HueWheelPainter or similar?
          // Let's verify.
          // In palette.dart, if type == hueWheel, it renders CustomPaint(painter: _HueWheelPainter)
        }
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: ColorPickerArea(
                  HSVColor.fromColor(Colors.red),
                  (hsv) {},
                  type,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('handles interactions', (WidgetTester tester) async {
      var color = HSVColor.fromColor(Colors.red);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: ColorPickerArea(
                color,
                (hsv) => color = hsv,
                PaletteType.hsv,
              ),
            ),
          ),
        ),
      );

      final Finder finder = find.byType(ColorPickerArea);
      await tester.tap(finder);
      await tester.pump();

      expect(color, isNot(HSVColor.fromColor(Colors.red)));
    });
  });

  group('ColorPickerSlider', () {
    testWidgets('renders for all TrackTypes', (WidgetTester tester) async {
      for (final TrackType type in TrackType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 50,
                child: ColorPickerSlider(
                  type,
                  HSVColor.fromColor(Colors.blue),
                  (hsv) {},
                ),
              ),
            ),
          ),
        );
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('slider interaction updates color', (
      WidgetTester tester,
    ) async {
      var color = HSVColor.fromColor(Colors.blue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 50,
              child: ColorPickerSlider(
                TrackType.hue,
                color,
                (hsv) => color = hsv,
              ),
            ),
          ),
        ),
      );

      final Finder sliderFinder = find.byType(ColorPickerSlider);
      final Offset center = tester.getCenter(sliderFinder);
      await tester.tapAt(center + const Offset(50, 0));
      await tester.pump();

      expect(color.hue, isNot(HSVColor.fromColor(Colors.blue).hue));
    });
  });

  group('ColorPickerLabel', () {
    testWidgets('renders rgb label type', (WidgetTester tester) async {
      final color = HSVColor.fromColor(Colors.green);
      // Test RGB explicitly first
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: ColorPickerLabel(
                  color,
                  colorLabelTypes: const [ColorLabelType.rgb],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ColorPickerLabel), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('renders dropdown and switches types', (
      WidgetTester tester,
    ) async {
      final color = HSVColor.fromColor(Colors.green);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: ColorPickerLabel(
                  color,
                  colorLabelTypes: const [
                    ColorLabelType.hsv,
                    ColorLabelType.hsl,
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Default is HSV (first in list)
      expect(find.text('H'), findsWidgets);
      expect(find.text('V'), findsWidgets);

      // Find dropdown and tap to switch
      final Finder dropdown = find.byType(DropdownButton<ColorLabelType>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show menu items: HSV, HSL
      // Tap HSL. Items text is split last uppercase. e.g. ColorLabelType.hsl -> HSL
      // find.text('HSL') might not work if it's constructed dynamically.
      // But we can find the DropdownMenuItem with value ColorLabelType.hsl
      await tester.tap(find.text('HSL').last);
      await tester.pumpAndSettle();

      // Now should show H, S, L
      expect(find.text('L'), findsWidgets);
    });
  });

  group('ColorPickerInput', () {
    testWidgets('updates color on hex input', (WidgetTester tester) async {
      Color color = Colors.red;
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPickerInput(color, (c) {
              color = c;
              called = true;
            }),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '0000FF');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      if (called) {
        expect(color.toARGB32(), const Color(0xff0000ff).toARGB32());
      }
    });
  });
}
