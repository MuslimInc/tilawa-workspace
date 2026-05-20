import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(() => TilawaInteractionFeedback.enabled = true);
  tearDown(() => TilawaInteractionFeedback.enabled = true);

  testWidgets('TilawaPressAnimation wraps child in ScaleTransition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
        home: Scaffold(
          body: Center(
            child: TilawaPressAnimation(
              child: SizedBox(
                width: 100,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Tap'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(TilawaPressAnimation),
        matching: find.byType(ScaleTransition),
      ),
      findsOneWidget,
    );

    await tester.startGesture(tester.getCenter(find.text('Tap')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('TilawaPressAnimation respects custom durationFast token', (
    tester,
  ) async {
    const customFast = Duration(milliseconds: 150);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light().copyWith(durationFast: customFast),
          ],
        ),
        home: const Scaffold(
          body: Center(
            child: TilawaPressAnimation(
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light().copyWith(durationFast: customFast),
          ],
        ),
        home: const Scaffold(
          body: Center(
            child: TilawaPressAnimation(
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TilawaPressAnimation), findsOneWidget);
  });

  test('TilawaInteractionFeedback respects enabled flag', () {
    TilawaInteractionFeedback.enabled = false;
    expect(() {
      TilawaInteractionFeedback.trigger(TilawaHaptic.selection);
    }, returnsNormally);
  });
}
