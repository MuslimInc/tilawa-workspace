import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final ThemeData theme = ThemeData(
    extensions: [MeMuslimDesignTokens.light()],
  );

  testWidgets('keeps primary Y when secondary visibility toggles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pump({required bool showSecondary}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaThumbReachLayout(
              useSafeArea: true,
              content: const SizedBox.expand(),
              actions: TilawaThumbReachActions(
                showSecondary: showSecondary,
                primary: TilawaButton(
                  text: 'Continue',
                  isFullWidth: true,
                  onPressed: () {},
                ),
                secondary: TilawaButton(
                  text: 'Back',
                  variant: TilawaButtonVariant.ghost,
                  isFullWidth: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(showSecondary: false);
    final double hiddenTop = tester
        .getRect(
          find.ancestor(
            of: find.text('Continue'),
            matching: find.byType(TextButton),
          ),
        )
        .top;

    await pump(showSecondary: true);
    final double shownTop = tester
        .getRect(
          find.ancestor(
            of: find.text('Continue'),
            matching: find.byType(TextButton),
          ),
        )
        .top;

    expect(shownTop, closeTo(hiddenTop, 1));
  });

  testWidgets('reserves maxLines height for short copy', (
    WidgetTester tester,
  ) async {
    const TextStyle style = TextStyle(fontSize: 20, height: 1.25);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: TilawaReservedTextLines(
                text: 'Hi',
                style: style,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size size = tester.getSize(find.byType(TilawaReservedTextLines));
    expect(size.height, closeTo(20 * 1.25 * 2, 0.5));
  });
}
