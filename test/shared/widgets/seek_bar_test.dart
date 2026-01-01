import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/seek_bar.dart';

void main() {
  group('SeekBar Widget Tests', () {
    testWidgets('renders correctly with given duration and position', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeekBar(
              duration: Duration(minutes: 5),
              position: Duration(minutes: 1),
            ),
          ),
        ),
      );

      // Verify two sliders are present (one for buffer, one for position)
      expect(find.byType(Slider), findsNWidgets(2));

      // Verify the primary slider value
      // Note: we can't easily check the exact visual position without intricate access,
      // but we can verify the widget structure is there.
    });

    testWidgets('triggers onChanged during drag', (tester) async {
      Duration? changedPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekBar(
              duration: const Duration(minutes: 10),
              position: Duration.zero,
              onChanged: (pos) => changedPosition = pos,
            ),
          ),
        ),
      );

      // Width of the slider is typically screen width - margin
      // Drag from left to middle
      final Finder sliderFinder = find
          .byType(Slider)
          .last; // The second slider is the interactive one
      await tester.drag(sliderFinder, const Offset(100, 0));
      await tester.pump();

      expect(changedPosition, isNotNull);
      expect(changedPosition!.inMilliseconds, greaterThan(0));
    });

    testWidgets('triggers onChangeEnd after drag completes', (tester) async {
      Duration? endPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeekBar(
              duration: const Duration(minutes: 10),
              position: Duration.zero,
              onChangeEnd: (pos) => endPosition = pos,
            ),
          ),
        ),
      );

      final Finder sliderFinder = find.byType(Slider).last;
      await tester.drag(sliderFinder, const Offset(100, 0));
      await tester.pumpAndSettle(); // Wait for drag to finish

      // Dragging itself doesn't trigger onChangeEnd in standard test drag immediately
      // unless we lift the pointer. tester.drag does move/up.

      expect(endPosition, isNotNull);
      expect(endPosition!.inMilliseconds, greaterThan(0));
    });

    testWidgets('handles zero duration gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeekBar(duration: Duration.zero, position: Duration.zero),
          ),
        ),
      );

      expect(find.byType(Slider), findsNWidgets(2));
      // Should not throw invalid argument assertion
    });

    testWidgets('respects buffered position', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeekBar(
              duration: Duration(minutes: 10),
              position: Duration(minutes: 1),
              bufferedPosition: Duration(minutes: 5),
            ),
          ),
        ),
      );

      // Verify visual components exist
      // In a real sophisticated test, we might check the layout of the RenderBox
      // or check Slider properties if we could access the State or the Slider widget properties directly.
      // Since Slider is inside the build method, we can find it structurally.

      final Iterable<Slider> sliders = tester.widgetList<Slider>(
        find.byType(Slider),
      );
      expect(sliders.length, 2);

      // First slider is buffered
      final Slider bufferedSlider = sliders.first;
      // Second slider is position
      final Slider positionSlider = sliders.last;

      expect(
        bufferedSlider.value,
        equals(const Duration(minutes: 5).inMilliseconds.toDouble()),
      );
      expect(
        positionSlider.value,
        equals(const Duration(minutes: 1).inMilliseconds.toDouble()),
      );
    });

    testWidgets('buffered slider onChanged callback executes without error', (
      tester,
    ) async {
      // This test covers line 77: the buffered slider's empty onChanged callback
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeekBar(
              duration: Duration(minutes: 10),
              position: Duration(minutes: 1),
              bufferedPosition: Duration(minutes: 5),
            ),
          ),
        ),
      );

      // Get the buffered slider (first one)
      final Iterable<Slider> sliders = tester.widgetList<Slider>(
        find.byType(Slider),
      );
      final Slider bufferedSlider = sliders.first;

      // Manually invoke the onChanged callback to cover line 77
      // The callback is intentionally empty, so just verify it doesn't throw
      expect(() => bufferedSlider.onChanged?.call(50.0), returnsNormally);
    });
  });
}
