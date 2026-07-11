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
  final MeMuslimDesignTokens tokens = MeMuslimDesignTokens.light();

  group('TilawaBottomActionArea', () {
    testWidgets('uses comfortable reach bottom spacing with zero safe area', (
      tester,
    ) async {
      const Key actionKey = Key('action');

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: TilawaBottomActionArea(
              child: SizedBox(key: actionKey, height: 48),
            ),
          ),
        ),
      );

      final AnimatedPadding animatedPadding = tester.widget<AnimatedPadding>(
        find.ancestor(
          of: find.byKey(actionKey),
          matching: find.byType(AnimatedPadding),
        ),
      );

      expect(
        (animatedPadding.padding as EdgeInsets).bottom,
        tokens.spaceHuge,
      );
    });

    testWidgets('uses tokenized horizontal inset for primary actions', (
      tester,
    ) async {
      const Key actionKey = Key('action');

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: TilawaBottomActionArea(
              child: SizedBox(key: actionKey, height: 48),
            ),
          ),
        ),
      );

      final AnimatedPadding animatedPadding = tester.widget<AnimatedPadding>(
        find.ancestor(
          of: find.byKey(actionKey),
          matching: find.byType(AnimatedPadding),
        ),
      );

      final EdgeInsets padding = animatedPadding.padding as EdgeInsets;

      expect(padding.left, tokens.bottomActionHorizontalInset);
      expect(padding.right, tokens.bottomActionHorizontalInset);
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
          home: const Scaffold(
            bottomNavigationBar: TilawaBottomActionArea(
              child: SizedBox(key: actionKey, height: 48),
            ),
            body: SizedBox(key: bodyKey, height: 200),
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

    testWidgets(
      'footer bottom padding stays token-sized when keyboard is open',
      (tester) async {
        const Key actionKey = Key('action');
        const double keyboardInset = 300;

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              resizeToAvoidBottomInset: true,
              body: MediaQuery(
                data: MediaQueryData(
                  viewInsets: EdgeInsets.only(bottom: keyboardInset),
                ),
                child: TilawaFormScreenScaffold(
                  body: Text('Body'),
                  footer: SizedBox(key: actionKey, height: 48),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final AnimatedPadding animatedPadding = tester.widget<AnimatedPadding>(
          find.ancestor(
            of: find.byKey(actionKey),
            matching: find.byType(AnimatedPadding),
          ),
        );

        final EdgeInsets padding = animatedPadding.padding as EdgeInsets;

        expect(padding.bottom, tokens.spaceSmall);
        expect(padding.bottom, lessThan(keyboardInset));
      },
    );

    testWidgets('footer bottom padding animates while keyboard dismisses', (
      tester,
    ) async {
      const Key actionKey = Key('action');
      const double keyboardInset = 300;
      late void Function({double? bottomInset}) setLayout;

      EdgeInsets readFooterPadding() {
        final AnimatedPadding animatedPadding = tester.widget<AnimatedPadding>(
          find.ancestor(
            of: find.byKey(actionKey),
            matching: find.byType(AnimatedPadding),
          ),
        );
        return animatedPadding.padding as EdgeInsets;
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: _KeyboardInsetHost(
              initialBottomInset: keyboardInset,
              builder: (setLayoutCallback) {
                setLayout = setLayoutCallback;
                return const TilawaFormScreenScaffold(
                  body: Text('Body'),
                  footer: SizedBox(key: actionKey, height: 48),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(readFooterPadding().bottom, tokens.spaceSmall);

      final double openTop = tester.getTopLeft(find.byKey(actionKey)).dy;

      setLayout(bottomInset: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      final double midTop = tester.getTopLeft(find.byKey(actionKey)).dy;
      expect(midTop, lessThan(openTop));

      await tester.pump(const Duration(milliseconds: 125));

      expect(readFooterPadding().bottom, tokens.spaceHuge);
      expect(
        tester.getTopLeft(find.byKey(actionKey)).dy,
        lessThan(openTop),
      );
    });

    testWidgets(
      'footer dismiss uses live closed padding without second target bump',
      (tester) async {
        const Key actionKey = Key('action');
        const double keyboardInset = 300;
        const double homeIndicatorInset = 34;
        late void Function({double? bottomInset, EdgeInsets? viewPadding})
        setLayout;

        double readFooterTarget() {
          final BuildContext context = tester.element(find.byKey(actionKey));
          return TilawaComfortableReachPadding.resolveClosed(
            context,
            kind: TilawaComfortableReachKind.screen,
          );
        }

        double readFooterPaddingBottom() {
          final AnimatedPadding animatedPadding = tester
              .widget<AnimatedPadding>(
                find.ancestor(
                  of: find.byKey(actionKey),
                  matching: find.byType(AnimatedPadding),
                ),
              );
          return (animatedPadding.padding as EdgeInsets).bottom;
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              body: _KeyboardInsetHost(
                initialBottomInset: keyboardInset,
                initialViewPadding: EdgeInsets.zero,
                builder: (setLayoutCallback) {
                  setLayout = setLayoutCallback;
                  return const TilawaFormScreenScaffold(
                    body: Text('Body'),
                    footer: SizedBox(key: actionKey, height: 48),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(readFooterPaddingBottom(), tokens.spaceSmall);

        setLayout(
          bottomInset: 0,
          viewPadding: const EdgeInsets.only(bottom: homeIndicatorInset),
        );
        await tester.pump();

        final double closedTarget = readFooterTarget();
        expect(
          closedTarget,
          homeIndicatorInset + tokens.spaceExtraLarge,
        );
        expect(readFooterPaddingBottom(), closedTarget);

        await tester.pump(const Duration(milliseconds: 250));

        expect(readFooterPaddingBottom(), closedTarget);
      },
    );
  });
}

class _KeyboardInsetHost extends StatefulWidget {
  const _KeyboardInsetHost({
    required this.initialBottomInset,
    this.initialViewPadding = EdgeInsets.zero,
    required this.builder,
  });

  final double initialBottomInset;
  final EdgeInsets initialViewPadding;
  final Widget Function(
    void Function({double? bottomInset, EdgeInsets? viewPadding}) setLayout,
  )
  builder;

  @override
  State<_KeyboardInsetHost> createState() => _KeyboardInsetHostState();
}

class _KeyboardInsetHostState extends State<_KeyboardInsetHost> {
  late double _bottomInset;
  late EdgeInsets _viewPadding;

  @override
  void initState() {
    super.initState();
    _bottomInset = widget.initialBottomInset;
    _viewPadding = widget.initialViewPadding;
  }

  void setLayout({double? bottomInset, EdgeInsets? viewPadding}) {
    setState(() {
      if (bottomInset != null) {
        _bottomInset = bottomInset;
      }
      if (viewPadding != null) {
        _viewPadding = viewPadding;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(
        viewInsets: EdgeInsets.only(bottom: _bottomInset),
        viewPadding: _viewPadding,
        padding: _viewPadding,
      ),
      child: widget.builder(setLayout),
    );
  }
}
