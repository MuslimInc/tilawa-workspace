import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/atoms/tilawa_button.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_bottom_action_area.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_comfortable_reach_padding.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_form_screen_scaffold.dart';

void main() {
  final ThemeData theme = AppTheme.getLightTheme(
    primaryColor: AppColors.defaultPrimary,
  );
  final TilawaDesignTokens tokens = TilawaDesignTokens.light();

  group('TilawaBottomActionArea', () {
    testWidgets('uses comfortable reach bottom spacing with zero safe area', (
      tester,
    ) async {
      const Key actionKey = Key('action');

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaBottomActionArea(
              child: const SizedBox(key: actionKey, height: 48),
            ),
          ),
        ),
      );

      final List<Padding> paddings = tester
          .widgetList<Padding>(
            find.ancestor(
              of: find.byKey(actionKey),
              matching: find.byType(Padding),
            ),
          )
          .toList();
      final EdgeInsets padding = paddings.first.padding as EdgeInsets;

      expect(padding.bottom, tokens.spaceHuge);
    });

    testWidgets('renders a top border by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: TilawaBottomActionArea(
              child: SizedBox(height: 48),
            ),
          ),
        ),
      );

      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('does not expand to fill scaffold bottomNavigationBar slot', (
      tester,
    ) async {
      const Key bodyKey = Key('body');
      const Key actionKey = Key('action');

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: TilawaBottomActionArea(
              child: const SizedBox(key: actionKey, height: 48),
            ),
            body: const SizedBox(key: bodyKey, height: 200),
          ),
        ),
      );

      final RenderBox bodyBox = tester.renderObject<RenderBox>(
        find.byKey(bodyKey),
      );
      final RenderBox actionBox = tester.renderObject<RenderBox>(
        find.byKey(actionKey),
      );

      expect(bodyBox.size.height, 200);
      expect(actionBox.size.height, 48);
      expect(
        tester.getTopLeft(find.byKey(actionKey)).dy,
        greaterThan(200),
      );
    });
  });

  group('TilawaFormScreenScaffold', () {
    testWidgets('keeps footer visible while body scrolls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: TilawaFormScreenScaffold(
                body: Column(
                  children: List<Widget>.generate(
                    20,
                    (int index) => SizedBox(
                      height: 48,
                      child: Text('Field $index'),
                    ),
                  ),
                ),
                footer: TilawaButton(
                  text: 'Save',
                  onPressed: () {},
                  isFullWidth: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Field 0'), findsOneWidget);

      await tester.drag(find.text('Field 0'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Field 19'), findsOneWidget);
    });

    testWidgets('footer uses screen comfortable reach padding', (
      tester,
    ) async {
      late double resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaFormScreenScaffold(
              body: const Text('Body'),
              footer: Builder(
                builder: (context) {
                  resolved = TilawaComfortableReachPadding.resolve(context);
                  return const SizedBox(height: 48);
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, tokens.spaceHuge);
    });
  });
}
