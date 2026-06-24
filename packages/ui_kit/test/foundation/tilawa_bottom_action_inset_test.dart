import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final ThemeData theme = ThemeData(
    extensions: <ThemeExtension<dynamic>>[TilawaDesignTokens.light()],
  );
  final TilawaDesignTokens tokens = TilawaDesignTokens.light();

  Future<EdgeInsets> pumpAndReadPadding(
    WidgetTester tester, {
    required Widget child,
    double top = 0,
    double extraBottom = 0,
    bool keyboardAware = false,
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            viewPadding: viewPadding,
            viewInsets: viewInsets,
          ),
          child: Scaffold(
            body: TilawaBottomActionInset(
              top: top,
              extraBottom: extraBottom,
              keyboardAware: keyboardAware,
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester.widget<Padding>(find.byType(Padding)).padding as EdgeInsets;
  }

  testWidgets('applies horizontal and top padding around child', (
    WidgetTester tester,
  ) async {
    final EdgeInsets padding = await pumpAndReadPadding(
      tester,
      top: tokens.spaceExtraLarge,
      child: const Text('Action'),
    );

    expect(padding.left, tokens.bottomActionHorizontalInset);
    expect(padding.top, tokens.spaceExtraLarge);
    expect(padding.right, tokens.bottomActionHorizontalInset);
  });

  testWidgets('uses floatingBottomPadding when system inset is present', (
    WidgetTester tester,
  ) async {
    const double systemBottom = 34;

    final EdgeInsets padding = await pumpAndReadPadding(
      tester,
      viewPadding: const EdgeInsets.only(bottom: systemBottom),
      child: const Text('Action'),
    );

    expect(padding.bottom, systemBottom + tokens.spaceSmall);
  });

  testWidgets('falls back to spaceExtraLarge when system inset is zero', (
    WidgetTester tester,
  ) async {
    final EdgeInsets padding = await pumpAndReadPadding(
      tester,
      child: const Text('Action'),
    );

    expect(padding.bottom, tokens.spaceExtraLarge);
  });

  testWidgets('adds extraBottom on top of floating padding', (
    WidgetTester tester,
  ) async {
    final EdgeInsets padding = await pumpAndReadPadding(
      tester,
      extraBottom: tokens.spaceLarge,
      child: const Text('Action'),
    );

    expect(padding.bottom, tokens.spaceExtraLarge + tokens.spaceLarge);
  });
}
