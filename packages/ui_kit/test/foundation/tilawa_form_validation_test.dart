import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_form_validation.dart';

void main() {
  group('TilawaFormValidationMessages', () {
    test('validationSummary uses Arabic plural rules', () {
      check(TilawaFormValidationMessages.validationSummary(0)).equals('');
      check(
        TilawaFormValidationMessages.validationSummary(1),
      ).equals('يرجى تصحيح حقل واحد مطلوب');
      check(
        TilawaFormValidationMessages.validationSummary(2),
      ).equals('يرجى تصحيح حقلين مطلوبين');
      check(
        TilawaFormValidationMessages.validationSummary(3),
      ).equals('يرجى تصحيح 3 حقول مطلوبة');
      check(
        TilawaFormValidationMessages.validationSummary(11),
      ).equals('يرجى تصحيح 11 حقلًا مطلوبًا');
    });

    test('accessibilityAnnouncement includes count and first field', () {
      check(
        TilawaFormValidationMessages.accessibilityAnnouncement(
          invalidCount: 3,
          firstFieldLabel: 'الجنس',
        ),
      ).equals('3 حقول تحتاج تصحيح. أول حقل: الجنس');
    });
  });

  group('TilawaFormValidationController', () {
    test('sortIssuesByFieldOrder respects registered field order', () {
      final TilawaFormValidationController controller =
          TilawaFormValidationController();
      controller.registerField(
        TilawaFormFieldRegistration(
          id: 'b',
          semanticLabel: 'B',
          order: 1,
          anchorKey: GlobalKey(),
        ),
      );
      controller.registerField(
        TilawaFormFieldRegistration(
          id: 'a',
          semanticLabel: 'A',
          order: 0,
          anchorKey: GlobalKey(),
        ),
      );

      final List<TilawaFormFieldIssue> sorted = controller
          .sortIssuesByFieldOrder(const <TilawaFormFieldIssue>[
            TilawaFormFieldIssue(fieldId: 'b', errorMessage: 'b'),
            TilawaFormFieldIssue(fieldId: 'a', errorMessage: 'a'),
          ]);

      check(sorted.first.fieldId).equals('a');
      controller.dispose();
    });

    test('firstIssue returns null for valid result', () {
      final TilawaFormValidationController controller =
          TilawaFormValidationController();
      check(
        controller.firstIssue(const TilawaFormValidationResult(issues: [])),
      ).isNull();
      controller.dispose();
    });

    test('registerField replaces existing registration by id', () {
      final TilawaFormValidationController controller =
          TilawaFormValidationController();
      final GlobalKey firstKey = GlobalKey();
      final GlobalKey secondKey = GlobalKey();
      controller.registerField(
        TilawaFormFieldRegistration(
          id: 'field',
          semanticLabel: 'First',
          order: 0,
          anchorKey: firstKey,
        ),
      );
      controller.registerField(
        TilawaFormFieldRegistration(
          id: 'field',
          semanticLabel: 'Second',
          order: 0,
          anchorKey: secondKey,
        ),
      );

      final TilawaFormFieldRegistration? registration = controller
          .firstRegistration(
            const TilawaFormValidationResult(
              issues: <TilawaFormFieldIssue>[
                TilawaFormFieldIssue(fieldId: 'field', errorMessage: 'err'),
              ],
            ),
          );

      check(registration?.semanticLabel).equals('Second');
      check(identical(registration?.anchorKey, secondKey)).isTrue();
      controller.dispose();
    });
  });

  group('TilawaFormValidationResult', () {
    test('isValid and invalidCount reflect issue list', () {
      const TilawaFormValidationResult empty = TilawaFormValidationResult(
        issues: <TilawaFormFieldIssue>[],
      );
      check(empty.isValid).isTrue();
      check(empty.invalidCount).equals(0);

      const TilawaFormValidationResult invalid = TilawaFormValidationResult(
        issues: <TilawaFormFieldIssue>[
          TilawaFormFieldIssue(fieldId: 'a', errorMessage: 'a'),
          TilawaFormFieldIssue(fieldId: 'b', errorMessage: 'b'),
        ],
      );
      check(invalid.isValid).isFalse();
      check(invalid.invalidCount).equals(2);
    });
  });
}
