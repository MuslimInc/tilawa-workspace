import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_action.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_style.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_feedback_strip.dart';

import 'golden_constraints.dart';
import 'golden_toast_fixtures.dart';

void main() {
  group('Foundation TilawaToast Golden Tests', () {
    goldenTest(
      'TilawaToast variants light',
      fileName: 'foundation/tilawa_toast_variants_light',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: <GoldenTestScenario>[
          for (final ({TilawaFeedbackVariant variant, String message}) scenario
              in <({TilawaFeedbackVariant variant, String message})>[
                (
                  variant: TilawaFeedbackVariant.success,
                  message: 'Bookmark saved',
                ),
                (
                  variant: TilawaFeedbackVariant.error,
                  message: 'Could not save changes',
                ),
                (
                  variant: TilawaFeedbackVariant.warning,
                  message: 'Location permission is limited',
                ),
                (
                  variant: TilawaFeedbackVariant.info,
                  message: 'Export ready to share',
                ),
              ])
            GoldenTestScenario(
              name: scenario.variant.name,
              child: goldenToastPreview(
                child: goldenToast(
                  variant: scenario.variant,
                  message: scenario.message,
                ),
              ),
            ),
        ],
      ),
    );

    goldenTest(
      'TilawaToast variants dark',
      fileName: 'foundation/tilawa_toast_variants_dark',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: <GoldenTestScenario>[
          for (final ({TilawaFeedbackVariant variant, String message}) scenario
              in <({TilawaFeedbackVariant variant, String message})>[
                (
                  variant: TilawaFeedbackVariant.success,
                  message: 'Bookmark saved',
                ),
                (
                  variant: TilawaFeedbackVariant.error,
                  message: 'Could not save changes',
                ),
                (
                  variant: TilawaFeedbackVariant.warning,
                  message: 'Location permission is limited',
                ),
                (
                  variant: TilawaFeedbackVariant.info,
                  message: 'Export ready to share',
                ),
              ])
            GoldenTestScenario(
              name: scenario.variant.name,
              child: goldenToastPreview(
                isDark: true,
                child: goldenToast(
                  variant: scenario.variant,
                  message: scenario.message,
                ),
              ),
            ),
        ],
      ),
    );

    goldenTest(
      'TilawaToast actionable',
      fileName: 'foundation/tilawa_toast_actionable',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: <GoldenTestScenario>[
          GoldenTestScenario(
            name: 'Undo',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.success,
                message: 'Bookmark deleted',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Undo', onPressed: _noop),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Retry',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.error,
                message: 'Upload failed',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Retry', onPressed: _noop),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dismiss',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.info,
                message: 'Update downloaded',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(
                    label: 'Dismiss',
                    onPressed: _noop,
                    kind: TilawaFeedbackActionKind.dismiss,
                  ),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Two actions',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.warning,
                message: 'Session cancelled',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Undo', onPressed: _noop),
                  TilawaFeedbackAction(
                    label: 'Dismiss',
                    onPressed: _noop,
                    kind: TilawaFeedbackActionKind.dismiss,
                  ),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Persistent update',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.warning,
                message: 'An update is required to continue using Tilawa.',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Update', onPressed: _noop),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaToast layout',
      fileName: 'foundation/tilawa_toast_layout',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: <GoldenTestScenario>[
          GoldenTestScenario(
            name: 'RTL Arabic undo',
            child: goldenToastPreview(
              isRTL: true,
              child: goldenToast(
                variant: TilawaFeedbackVariant.success,
                message: 'تم حذف الإشارة المرجعية',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'تراجع', onPressed: _noop),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic long',
            child: goldenToastPreview(
              isRTL: true,
              child: goldenToast(
                variant: TilawaFeedbackVariant.info,
                message: kGoldenToastLongArabicMessage,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Text scale 1.4',
            child: goldenToastPreview(
              textScale: 1.4,
              child: goldenToast(
                variant: TilawaFeedbackVariant.success,
                message: kGoldenToastLongEnglishMessage,
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Undo', onPressed: _noop),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark actionable',
            child: goldenToastPreview(
              isDark: true,
              child: goldenToast(
                variant: TilawaFeedbackVariant.error,
                message: 'Could not remove slot',
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Retry', onPressed: _noop),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaToast edge cases',
      fileName: 'foundation/tilawa_toast_edge_cases',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: <GoldenTestScenario>[
          GoldenTestScenario(
            name: 'Long English',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.success,
                message: kGoldenToastLongEnglishMessage,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Long English persistent',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.warning,
                message: kGoldenToastLongEnglishMessage,
                actions: const <TilawaFeedbackAction>[
                  TilawaFeedbackAction(label: 'Update', onPressed: _noop),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Spinner leading',
            child: goldenToastPreview(
              child: Builder(
                builder: (BuildContext context) {
                  final TilawaFeedbackStyle style =
                      TilawaFeedbackStyle.forVariant(
                        context,
                        TilawaFeedbackVariant.info,
                      );
                  return goldenToastSpinnerStrip(
                    message: 'Syncing your changes',
                    backgroundColor: style.backgroundColor,
                    foregroundColor: style.foregroundColor,
                  );
                },
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Short icon toast',
            child: goldenToastPreview(
              child: goldenToast(
                variant: TilawaFeedbackVariant.success,
                message: 'Saved',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Short spinner toast',
            child: goldenToastPreview(
              child: Builder(
                builder: (BuildContext context) {
                  final TilawaFeedbackStyle style =
                      TilawaFeedbackStyle.forVariant(
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
            ),
          ),
        ],
      ),
    );

    testWidgets('action buttons meet 48dp minimum touch target in goldens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        goldenToastPreview(
          child: goldenToast(
            variant: TilawaFeedbackVariant.success,
            message: 'Bookmark deleted',
            actions: const <TilawaFeedbackAction>[
              TilawaFeedbackAction(label: 'Undo', onPressed: _noop),
            ],
          ),
        ),
      );

      final TextButton button = tester.widget(
        find.widgetWithText(TextButton, 'Undo'),
      );
      final Size? minimumSize = button.style?.minimumSize?.resolve({});
      expect(minimumSize?.width, kMeMuslimMinInteractiveDimension);
      expect(minimumSize?.height, kMeMuslimMinInteractiveDimension);
    });
  });
}

void _noop() {}
