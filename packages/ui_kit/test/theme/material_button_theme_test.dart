import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

Widget _themedApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(body: Center(child: child)),
  );
}

ButtonStyle _themeButtonStyle(BuildContext context, Type buttonType) {
  final ThemeData theme = Theme.of(context);
  if (buttonType == FilledButton) {
    return theme.filledButtonTheme.style!;
  }
  if (buttonType == OutlinedButton) {
    return theme.outlinedButtonTheme.style!;
  }
  if (buttonType == ElevatedButton) {
    return theme.elevatedButtonTheme.style!;
  }
  if (buttonType == TextButton) {
    return theme.textButtonTheme.style!;
  }
  throw ArgumentError('Unsupported button type: $buttonType');
}

BorderRadius _resolvedPillRadius(WidgetTester tester, Type buttonType) {
  final BuildContext context = tester.element(find.byType(buttonType));
  final RoundedRectangleBorder shape =
      _themeButtonStyle(context, buttonType).shape!.resolve(const {})!
          as RoundedRectangleBorder;
  return shape.borderRadius as BorderRadius;
}

void main() {
  group('Material button widgets inherit AppTheme pill shape', () {
    final TilawaDesignTokens tokens = TilawaDesignTokens.light();
    final BorderRadius expectedPill = BorderRadius.circular(
      tokens.buttonBorderRadius(),
    );

    testWidgets('FilledButton uses token pill radius', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          FilledButton(onPressed: () {}, child: const Text('Continue')),
        ),
      );

      expect(_resolvedPillRadius(tester, FilledButton), expectedPill);
    });

    testWidgets('OutlinedButton uses token pill radius', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
        ),
      );

      expect(_resolvedPillRadius(tester, OutlinedButton), expectedPill);
    });

    testWidgets('ElevatedButton uses token pill radius', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          ElevatedButton(onPressed: () {}, child: const Text('Retry')),
        ),
      );

      expect(_resolvedPillRadius(tester, ElevatedButton), expectedPill);
    });

    testWidgets('TextButton uses token pill radius', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          TextButton(onPressed: () {}, child: const Text('Skip')),
        ),
      );

      expect(_resolvedPillRadius(tester, TextButton), expectedPill);
    });

    testWidgets('all four Material buttons share identical pill radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themedApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              TextButton(onPressed: () {}, child: const Text('Text')),
            ],
          ),
        ),
      );

      final BorderRadius filled = _resolvedPillRadius(tester, FilledButton);
      final BorderRadius outlined = _resolvedPillRadius(tester, OutlinedButton);
      final BorderRadius elevated = _resolvedPillRadius(tester, ElevatedButton);
      final BorderRadius text = _resolvedPillRadius(tester, TextButton);

      expect(outlined, filled);
      expect(elevated, filled);
      expect(text, filled);
      expect(filled, expectedPill);
    });
  });

  group('materialButtonStyle', () {
    test('merges pill shape onto an existing ButtonStyle', () {
      final tokens = TilawaDesignTokens.light();
      const ButtonStyle base = ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(Colors.red),
      );

      final ButtonStyle merged = tokens.materialButtonStyle(base: base);
      final RoundedRectangleBorder shape =
          merged.shape!.resolve(const {})! as RoundedRectangleBorder;

      expect(shape.borderRadius, BorderRadius.circular(24));
      expect(
        merged.foregroundColor!.resolve(const {}),
        Colors.red,
      );
    });
  });
}
