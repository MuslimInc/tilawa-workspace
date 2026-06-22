import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_bottom_action_area.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_action.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_host.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_insets.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_style.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_interaction_feedback.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_feedback_strip.dart';

import '../goldens/golden_toast_fixtures.dart';

void main() {
  final ThemeData theme = AppTheme.getLightTheme(
    primaryColor: AppColors.defaultPrimary,
  );

  setUp(() {
    TilawaInteractionFeedback.enabled = false;
  });

  Future<void> pumpHost(
    WidgetTester tester, {
    required Widget child,
    Locale locale = const Locale('en'),
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        home: Directionality(
          textDirection: textDirection,
          child: TilawaFeedbackHost(child: child),
        ),
      ),
    );
  }

  group('TilawaFeedback.showToast', () {
    testWidgets('renders success toast with strip message', (tester) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showToast(
                  context,
                  message: 'Bookmark deleted',
                  variant: TilawaFeedbackVariant.success,
                );
              },
              child: const Text('Show'),
            );
          },
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Bookmark deleted'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders error toast with semantic error colour', (
      tester,
    ) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showToast(
                  context,
                  message: 'Save failed',
                  variant: TilawaFeedbackVariant.error,
                );
              },
              child: const Text('Show error'),
            );
          },
        ),
      );

      await tester.tap(find.text('Show error'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Save failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final TilawaFeedbackStrip strip = tester.widget(
        find.byType(TilawaFeedbackStrip),
      );
      final ColorScheme scheme = theme.colorScheme;
      check(strip.backgroundColor).equals(scheme.surfaceContainerHigh);
      check(strip.foregroundColor).equals(scheme.error);
    });

    testWidgets('lays out icon before message in RTL', (tester) async {
      await pumpHost(
        tester,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showToast(
                  context,
                  message: 'تم الحذف',
                  variant: TilawaFeedbackVariant.success,
                );
              },
              child: const Text('عرض'),
            );
          },
        ),
      );

      await tester.tap(find.text('عرض'));
      await tester.pump();
      await tester.pump();

      final Finder rowFinder = find.descendant(
        of: find.byType(TilawaFeedbackStrip),
        matching: find.byType(Row),
      );
      final Row row = tester.widget(rowFinder);
      check(Directionality.of(tester.element(rowFinder))).equals(
        TextDirection.rtl,
      );

      final List<Widget> children = row.children;
      check(children.first.runtimeType.toString()).equals('_LeadingSlot');
      check(children[1]).isA<Expanded>();
      expect(
        find.descendant(of: rowFinder, matching: find.byType(Icon)),
        findsOneWidget,
      );
    });

    testWidgets('auto dismisses after duration elapses', (tester) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showToast(
                  context,
                  message: 'Gone soon',
                  variant: TilawaFeedbackVariant.info,
                  duration: const Duration(milliseconds: 200),
                );
              },
              child: const Text('Show brief'),
            );
          },
        ),
      );

      await tester.tap(find.text('Show brief'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Gone soon'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Gone soon'), findsNothing);
    });

    testWidgets('floats above reported sticky footer obstruction', (
      tester,
    ) async {
      const double obstruction = 96;

      await pumpHost(
        tester,
        child: TilawaFeedbackInsets(
          bottomObstruction: obstruction,
          child: Builder(
            builder: (context) {
              return Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      TilawaFeedback.showToast(
                        context,
                        message: 'Above footer',
                        variant: TilawaFeedbackVariant.success,
                      );
                    },
                    child: const Text('Show'),
                  ),
                  const Spacer(),
                  const SizedBox(
                    height: obstruction,
                    child: TilawaBottomActionArea(
                      child: Text('Submit'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump();

      final Finder positionedFinder = find.ancestor(
        of: find.byType(TilawaFeedbackStrip),
        matching: find.byType(Positioned),
      );
      final Positioned positioned = tester.widget(positionedFinder);
      check(positioned.bottom).isNotNull();
      check(positioned.bottom!).isGreaterThan(obstruction);
    });

    testWidgets('exposes live region semantics on toast message', (
      tester,
    ) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showToast(
                  context,
                  message: 'Accessible toast',
                  variant: TilawaFeedbackVariant.success,
                );
              },
              child: const Text('Show'),
            );
          },
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pumpAndSettle();

      final SemanticsHandle handle = tester.ensureSemantics();
      final SemanticsNode messageSem = tester.getSemantics(
        find.text('Accessible toast'),
      );
      check(messageSem.flagsCollection.isLiveRegion).isTrue();
      handle.dispose();
    });
  });

  group('TilawaFeedback.showActionable', () {
    testWidgets('renders undo action with minimum touch target', (
      tester,
    ) async {
      var undone = false;

      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showActionable(
                  context,
                  message: 'Bookmark deleted',
                  variant: TilawaFeedbackVariant.success,
                  actions: <TilawaFeedbackAction>[
                    TilawaFeedbackAction(
                      label: 'Undo',
                      onPressed: () => undone = true,
                    ),
                  ],
                );
              },
              child: const Text('Delete'),
            );
          },
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Bookmark deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      final TextButton undoButton = tester.widget(
        find.widgetWithText(TextButton, 'Undo'),
      );
      check(undoButton.style?.minimumSize?.resolve({})).equals(
        const Size(
          kTilawaMinInteractiveDimension,
          kTilawaMinInteractiveDimension,
        ),
      );

      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pumpAndSettle();

      check(undone).isTrue();
      expect(find.text('Bookmark deleted'), findsNothing);
    });

    testWidgets('dismiss by dedupeKey removes active actionable toast', (
      tester,
    ) async {
      const dedupeKey = 'test-undo';

      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    TilawaFeedback.showActionable(
                      context,
                      message: 'Slot removed',
                      variant: TilawaFeedbackVariant.success,
                      dedupeKey: dedupeKey,
                      actions: <TilawaFeedbackAction>[
                        TilawaFeedbackAction(
                          label: 'Undo',
                          onPressed: () {},
                        ),
                      ],
                    );
                  },
                  child: const Text('Show'),
                ),
                ElevatedButton(
                  onPressed: () {
                    TilawaFeedback.dismiss(context, dedupeKey: dedupeKey);
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            );
          },
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Slot removed'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Slot removed'), findsNothing);
    });

    testWidgets('stays visible when duration is null', (tester) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                TilawaFeedback.showActionable(
                  context,
                  message: 'Required update',
                  variant: TilawaFeedbackVariant.warning,
                  duration: null,
                  actions: <TilawaFeedbackAction>[
                    TilawaFeedbackAction(
                      label: 'Update',
                      onPressed: () {},
                    ),
                  ],
                );
              },
              child: const Text('Show persistent'),
            );
          },
        ),
      );

      await tester.tap(find.text('Show persistent'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Required update'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(find.text('Required update'), findsOneWidget);
    });

    testWidgets('dedupes identical dedupeKey while active', (tester) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return Column(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    TilawaFeedback.showToast(
                      context,
                      message: 'First',
                      variant: TilawaFeedbackVariant.info,
                      dedupeKey: 'same-key',
                    );
                  },
                  child: const Text('First'),
                ),
                ElevatedButton(
                  onPressed: () {
                    TilawaFeedback.showToast(
                      context,
                      message: 'Second',
                      variant: TilawaFeedbackVariant.info,
                      dedupeKey: 'same-key',
                    );
                  },
                  child: const Text('Second'),
                ),
              ],
            );
          },
        ),
      );

      await tester.tap(find.text('First'));
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(TilawaFeedbackStrip),
          matching: find.text('First'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(TilawaFeedbackStrip),
          matching: find.text('First'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TilawaFeedbackStrip),
          matching: find.text('Second'),
        ),
        findsNothing,
      );
    });

    testWidgets('clamps toast message to two lines with ellipsis', (
      tester,
    ) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.info,
                message: kGoldenToastLongEnglishMessage,
              ),
            );
          },
        ),
      );

      final Text message = tester.widget<Text>(
        find.descendant(
          of: find.byType(TilawaFeedbackStrip),
          matching: find.byType(Text),
        ),
      );
      check(message.maxLines).equals(2);
      check(message.overflow).equals(TextOverflow.ellipsis);
    });

    testWidgets('keeps full message in semantics when visually ellipsized', (
      tester,
    ) async {
      await pumpHost(
        tester,
        child: Builder(
          builder: (context) {
            return goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.info,
                message: kGoldenToastLongEnglishMessage,
              ),
            );
          },
        ),
      );

      final SemanticsHandle handle = tester.ensureSemantics();
      final SemanticsNode node = tester.getSemantics(
        find.descendant(
          of: find.byType(TilawaFeedbackStrip),
          matching: find.byType(Text),
        ),
      );
      check(node.label).contains(kGoldenToastLongEnglishMessage);
      handle.dispose();
    });

    testWidgets('spinner and icon toasts share reserved content height', (
      tester,
    ) async {
      Future<double> toastContentHeight(Widget toast) async {
        await pumpHost(
          tester,
          child: Builder(
            builder: (context) => goldenToastPreview(child: toast),
          ),
        );
        final Rect bounds = tester.getRect(find.byType(TilawaFeedbackStrip));
        return bounds.height;
      }

      final double iconHeight = await toastContentHeight(
        goldenToast(
          variant: TilawaFeedbackVariant.info,
          message: 'Saved',
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final double spinnerHeight = await toastContentHeight(
        Builder(
          builder: (context) {
            final TilawaFeedbackStyle style = TilawaFeedbackStyle.forVariant(
              context,
              TilawaFeedbackVariant.info,
            );
            return goldenToastSpinnerStrip(
              message: 'Saved',
              backgroundColor: style.backgroundColor,
              foregroundColor: style.foregroundColor,
            );
          },
        ),
      );

      check(spinnerHeight).equals(iconHeight);
    });
  });
}
