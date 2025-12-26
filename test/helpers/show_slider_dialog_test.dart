import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/helpers/show_slider_dialog.dart';

void main() {
  testWidgets('showSliderDialog displays correctly and handles changes', (
    tester,
  ) async {
    var updatedValue = 0.5;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showSliderDialog(
                    context: context,
                    title: 'Test Title',
                    divisions: 10,
                    min: 0.0,
                    max: 1.0,
                    value: 0.5,
                    valueSuffix: 'x',
                    onChanged: (value) {
                      updatedValue = value;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Initial state: Dialog not shown
    expect(find.text('Test Title'), findsNothing);

    // Trigger dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('0.5x'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Drag slider to the right
    final Finder sliderFinder = find.byType(Slider);
    final Offset center = tester.getCenter(sliderFinder);
    await tester.drag(sliderFinder, const Offset(50, 0));
    await tester.pumpAndSettle();

    // Verify value changed
    expect(updatedValue, greaterThan(0.5));

    // Verify UI updated with new value
    final newValueText = '${updatedValue.toStringAsFixed(1)}x';
    expect(find.text(newValueText), findsOneWidget);
  });
}
