import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/atoms/tilawa_button.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_form_field_anchor.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_form_screen_scaffold.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_form_submit_footer.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_form_validation.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_interaction_feedback.dart';

void main() {
  final ThemeData theme = AppTheme.getLightTheme(
    primaryColor: AppColors.defaultPrimary,
  );

  setUp(() {
    TilawaInteractionFeedback.enabled = false;
  });

  group('TilawaFormSubmitFooter', () {
    testWidgets('shows validation summary above enabled primary button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaFormSubmitFooter(
              buttonText: 'Submit',
              invalidFieldCount: 3,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('يرجى تصحيح 3 حقول مطلوبة'), findsOneWidget);
      final TilawaButton button = tester.widget(find.byType(TilawaButton));
      check(button.onPressed).isNotNull();
    });

    testWidgets('hides summary when invalidFieldCount is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaFormSubmitFooter(
              buttonText: 'Submit',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('يرجى تصحيح'), findsNothing);
    });
  });

  group('TilawaFormFieldAnchor', () {
    testWidgets('registers field with validation controller', (tester) async {
      final TilawaFormValidationController controller =
          TilawaFormValidationController();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaFormScreenScaffold(
              validationController: controller,
              body: const TilawaFormFieldAnchor(
                fieldId: 'alpha',
                semanticLabel: 'Alpha',
                order: 0,
                child: Text('Alpha field'),
              ),
              footer: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      final TilawaFormFieldRegistration? registration = controller
          .firstRegistration(
            const TilawaFormValidationResult(
              issues: <TilawaFormFieldIssue>[
                TilawaFormFieldIssue(fieldId: 'alpha', errorMessage: 'bad'),
              ],
            ),
          );

      check(registration).isNotNull();
      check(registration!.semanticLabel).equals('Alpha');
      controller.dispose();
    });
  });

  group('scroll-to-first-error', () {
    testWidgets('scrolls to first invalid field in display order', (
      tester,
    ) async {
      final TilawaFormValidationController controller =
          TilawaFormValidationController();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                height: 400,
                child: TilawaFormScreenScaffold(
                  validationController: controller,
                  body: Column(
                    children: <Widget>[
                      const TilawaFormFieldAnchor(
                        fieldId: 'first',
                        semanticLabel: 'First',
                        order: 0,
                        child: SizedBox(
                          height: 48,
                          child: Text('First'),
                        ),
                      ),
                      ...List<Widget>.generate(
                        12,
                        (int index) => SizedBox(
                          height: 120,
                          child: Text('Spacer $index'),
                        ),
                      ),
                      const TilawaFormFieldAnchor(
                        fieldId: 'last',
                        semanticLabel: 'Last',
                        order: 1,
                        child: SizedBox(
                          height: 48,
                          child: Text('Last'),
                        ),
                      ),
                    ],
                  ),
                  footer: const SizedBox(height: 48),
                ),
              ),
            ),
          ),
        ),
      );

      check(controller.scrollController.hasClients).isTrue();
      final double topOffset = controller.scrollController.offset;

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      check(controller.scrollController.offset).isGreaterThan(topOffset);

      await controller.handleValidationFailure(
        tester.element(find.byType(Scaffold)),
        const TilawaFormValidationResult(
          issues: <TilawaFormFieldIssue>[
            TilawaFormFieldIssue(fieldId: 'last', errorMessage: 'last bad'),
            TilawaFormFieldIssue(fieldId: 'first', errorMessage: 'first bad'),
          ],
        ),
        scrollDuration: Duration.zero,
      );
      await tester.pump();

      check(controller.scrollController.offset).isLessThan(48.0);
      controller.dispose();
    });

    testWidgets('requests focus on first invalid text field', (tester) async {
      final TilawaFormValidationController controller =
          TilawaFormValidationController();
      final FocusNode focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: TilawaFormScreenScaffold(
              validationController: controller,
              body: TilawaFormFieldAnchor(
                fieldId: 'phone',
                semanticLabel: 'Phone',
                order: 0,
                focusNode: focusNode,
                child: TextField(focusNode: focusNode),
              ),
              footer: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await controller.handleValidationFailure(
        tester.element(find.byType(Scaffold)),
        const TilawaFormValidationResult(
          issues: <TilawaFormFieldIssue>[
            TilawaFormFieldIssue(fieldId: 'phone', errorMessage: 'required'),
          ],
        ),
      );
      await tester.pump();

      check(focusNode.hasFocus).isTrue();
      focusNode.dispose();
      controller.dispose();
    });

    testWidgets(
      'handleValidationFailure completes without error in RTL layout',
      (
        tester,
      ) async {
        final TilawaFormValidationController controller =
            TilawaFormValidationController();

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: TilawaFormScreenScaffold(
                  validationController: controller,
                  body: const TilawaFormFieldAnchor(
                    fieldId: 'gender',
                    semanticLabel: 'الجنس',
                    order: 0,
                    child: Text('Gender'),
                  ),
                  footer: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );

        await controller.handleValidationFailure(
          tester.element(find.byType(Scaffold)),
          const TilawaFormValidationResult(
            issues: <TilawaFormFieldIssue>[
              TilawaFormFieldIssue(fieldId: 'gender', errorMessage: 'required'),
            ],
          ),
        );
        await tester.pumpAndSettle();
        controller.dispose();
      },
    );
  });

  group('TilawaFormSectionError', () {
    testWidgets('renders error text with theme error color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: TilawaFormSectionError(errorText: 'خطأ'),
          ),
        ),
      );

      final Text error = tester.widget(find.text('خطأ'));
      final ColorScheme scheme = theme.colorScheme;
      check(error.style?.color).equals(scheme.error);
    });
  });
}
