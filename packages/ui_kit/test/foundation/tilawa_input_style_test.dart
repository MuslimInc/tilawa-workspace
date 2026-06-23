import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_input_style.dart';

void main() {
  group('TilawaInputStyle', () {
    late ThemeData theme;
    late TilawaDesignTokens tokens;

    setUp(() {
      theme = AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary);
      tokens = theme.tokens;
    });

    Widget wrap(Widget child) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('form decoration uses chrome radius and explicit borders', (
      tester,
    ) async {
      late TilawaInputStyle style;
      late InputDecoration deco;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              style = context.inputStyle();
              deco = style.decoration(hintText: 'Hint');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final double expectedRadius = tokens.resolveRadius(
        family: TilawaRadiusFamily.chrome,
      );
      final enabled = deco.enabledBorder! as OutlineInputBorder;
      expect(enabled.borderRadius, BorderRadius.circular(expectedRadius));
      expect(deco.focusedBorder, isNotNull);
      expect(deco.errorBorder, isNotNull);
      expect(deco.filled, isTrue);
    });

    testWidgets('search role resolves pill radius from field height', (
      tester,
    ) async {
      late TilawaInputStyle style;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              style = context.inputStyle(
                role: TilawaInputRole.search,
                fieldHeight: 48,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(style.borderRadius(height: 48), 24);
    });

    testWidgets('borderlessDecoration clears every border slot', (
      tester,
    ) async {
      late InputDecoration deco;

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              deco = context
                  .inputStyle(role: TilawaInputRole.search)
                  .borderlessDecoration(hintText: 'Search');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(deco.border, InputBorder.none);
      expect(deco.enabledBorder, InputBorder.none);
      expect(deco.focusedBorder, InputBorder.none);
      expect(deco.disabledBorder, InputBorder.none);
      expect(deco.errorBorder, InputBorder.none);
      expect(deco.focusedErrorBorder, InputBorder.none);
    });
  });
}
