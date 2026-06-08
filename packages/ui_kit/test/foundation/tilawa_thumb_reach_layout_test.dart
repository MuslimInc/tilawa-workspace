import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final ThemeData theme = ThemeData(
    extensions: [TilawaDesignTokens.light()],
  );

  Future<void> pumpLayout(
    WidgetTester tester, {
    required Widget actions,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: TilawaThumbReachLayout(
            content: const ColoredBox(
              color: Color(0xFFE0E0E0),
              child: SizedBox.expand(),
            ),
            actions: actions,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts the action band near 72% of the screen height', (
    WidgetTester tester,
  ) async {
    await pumpLayout(
      tester,
      actions: const SizedBox(height: 24, child: Text('Action')),
    );

    final Rect screen = tester.getRect(find.byType(Scaffold));
    final Rect action = tester.getRect(find.text('Action'));

    final double bandStart = screen.height *
        TilawaThumbReachLayout.actionBandStartFraction();

    expect(action.top, greaterThanOrEqualTo(bandStart - 1));
    expect(action.top, lessThan(bandStart + screen.height * 0.08));
  });

  testWidgets('keeps action controls at intrinsic height', (
    WidgetTester tester,
  ) async {
    await pumpLayout(
      tester,
      actions: TilawaButton(
        text: 'Continue',
        size: TilawaButtonSize.large,
        isFullWidth: true,
        onPressed: () {},
      ),
    );

    final Rect button = tester.getRect(
      find.ancestor(
        of: find.text('Continue'),
        matching: find.byType(TextButton),
      ),
    );

    expect(button.height, lessThan(80));
    expect(button.height, greaterThan(48));
  });
}
