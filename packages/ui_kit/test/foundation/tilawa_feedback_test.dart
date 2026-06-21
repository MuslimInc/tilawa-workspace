import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_bottom_action_area.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_host.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_insets.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_interaction_feedback.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_feedback_strip.dart';

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
      check(children.first).isA<Icon>();
      check(children.last).isA<Expanded>();
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
}
