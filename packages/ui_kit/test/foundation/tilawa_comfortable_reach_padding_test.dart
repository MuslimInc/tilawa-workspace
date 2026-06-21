import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_comfortable_reach_padding.dart';

void main() {
  final ThemeData theme = AppTheme.getLightTheme(
    primaryColor: AppColors.defaultPrimary,
  );
  final TilawaDesignTokens tokens = TilawaDesignTokens.light();

  Future<double> pumpAndResolve(
    WidgetTester tester, {
    TilawaComfortableReachKind kind = TilawaComfortableReachKind.screen,
    double keyboardBuffer = 0,
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    late double resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            viewPadding: viewPadding,
            viewInsets: viewInsets,
          ),
          child: Builder(
            builder: (context) {
              resolved = TilawaComfortableReachPadding.resolve(
                context,
                kind: kind,
                keyboardBuffer: keyboardBuffer,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return resolved;
  }

  group('TilawaComfortableReachPadding', () {
    testWidgets('screen and sheet use spaceHuge without safe area', (
      tester,
    ) async {
      final screen = await pumpAndResolve(tester);
      final sheet = await pumpAndResolve(
        tester,
        kind: TilawaComfortableReachKind.sheet,
      );

      expect(screen, tokens.spaceHuge);
      expect(sheet, tokens.spaceHuge);
    });

    testWidgets('adds spaceExtraLarge above system bottom inset', (
      tester,
    ) async {
      const double inset = 34;

      final resolved = await pumpAndResolve(
        tester,
        viewPadding: const EdgeInsets.only(bottom: inset),
      );

      expect(resolved, inset + tokens.spaceExtraLarge);
    });

    testWidgets('floating delegates to floatingBottomPadding', (
      tester,
    ) async {
      final resolved = await pumpAndResolve(
        tester,
        kind: TilawaComfortableReachKind.floating,
      );

      expect(resolved, tokens.spaceExtraLarge);
    });

    testWidgets('keyboard adds inset plus buffer', (tester) async {
      const double keyboard = 280;

      final resolved = await pumpAndResolve(
        tester,
        viewInsets: const EdgeInsets.only(bottom: keyboard),
        keyboardBuffer: 16,
      );

      expect(resolved, keyboard + 16);
    });
  });
}
