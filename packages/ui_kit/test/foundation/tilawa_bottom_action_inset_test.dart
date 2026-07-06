import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final ThemeData theme = ThemeData(
    extensions: <ThemeExtension<dynamic>>[MeMuslimDesignTokens.light()],
  );
  final MeMuslimDesignTokens tokens = MeMuslimDesignTokens.light();

  Future<EdgeInsets> pumpAndReadPadding(
    WidgetTester tester, {
    required Widget child,
    double top = 0,
    double extraBottom = 0,
    double? minBottom,
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
              minBottom: minBottom,
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

  // Keyboard-visible cases deliberately omit the [Scaffold]: a default Scaffold
  // strips bottom [MediaQuery.viewInsets] from its resized body, so the inset
  // must be read directly under [MediaQuery] for the simulated keyboard height
  // to reach [TilawaSafeAreaX.effectiveKeyboardInset].
  Future<EdgeInsets> pumpKeyboardVisiblePadding(
    WidgetTester tester, {
    required Widget child,
    double extraBottom = 0,
    double? minBottom,
    bool keyboardAware = false,
    required double keyboardInset,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            viewPadding: viewPadding,
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: TilawaBottomActionInset(
            extraBottom: extraBottom,
            minBottom: minBottom,
            keyboardAware: keyboardAware,
            child: child,
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

  testWidgets('respects minBottom when the keyboard is hidden', (
    WidgetTester tester,
  ) async {
    const double minBottom = 40;

    final EdgeInsets padding = await pumpAndReadPadding(
      tester,
      minBottom: minBottom,
      child: const Text('Action'),
    );

    // minBottom (40) exceeds the zero-inset fallback (spaceExtraLarge = 24).
    expect(padding.bottom, minBottom);
  });

  group('keyboard visible (non-keyboardAware, resize-aware residual)', () {
    testWidgets(
      'subtracts the keyboard inset so it is not double-counted with the '
      'ancestor resize — leaves only spaceMedium of residual padding',
      (WidgetTester tester) async {
        final EdgeInsets padding = await pumpKeyboardVisiblePadding(
          tester,
          keyboardInset: 300,
          child: const Text('Action'),
        );

        // targetTotal = max(24, 300 + 12) = 312; residual = 312 - 300 = 12.
        expect(padding.bottom, tokens.spaceMedium);
      },
    );

    testWidgets('keeps extraBottom clearance above the keyboard residual', (
      WidgetTester tester,
    ) async {
      final EdgeInsets padding = await pumpKeyboardVisiblePadding(
        tester,
        keyboardInset: 300,
        extraBottom: tokens.spaceLarge,
        child: const Text('Action'),
      );

      // extraBottom must survive the inset subtraction untouched.
      expect(padding.bottom, tokens.spaceMedium + tokens.spaceLarge);
    });
  });

  group('keyboardAware: true', () {
    testWidgets('lifts the full keyboard inset plus a small buffer', (
      WidgetTester tester,
    ) async {
      final EdgeInsets padding = await pumpKeyboardVisiblePadding(
        tester,
        keyboardAware: true,
        keyboardInset: 300,
        child: const Text('Action'),
      );

      // max(basePadding = 24, 300 + spaceSmall) = 308.
      expect(padding.bottom, 300 + tokens.spaceSmall);
    });
  });
}
