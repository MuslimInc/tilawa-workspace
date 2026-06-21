import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../rtl_test_matrix.dart';

Widget _themedApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaCupertinoWheelPicker', () {
    testInBothDirections('keeps wheel columns LTR inside RTL app', (
      tester,
      direction,
    ) async {
      await pumpWithDirection(
        tester,
        _themedApp(
          TilawaCupertinoWheelPicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2020, 1, 1, 9, 0),
            onDateTimeChanged: (_) {},
          ),
        ),
        direction,
      );

      final pickerDirectionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(TilawaCupertinoWheelPicker),
          matching: find.byType(Directionality),
        ),
      );
      expect(pickerDirectionality.textDirection, TextDirection.ltr);
    });

    testWidgets('uses token picker height', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          TilawaCupertinoWheelPicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2020, 1, 1, 9, 0),
            onDateTimeChanged: (_) {},
          ),
        ),
      );

      final theme = Theme.of(
        tester.element(find.byType(TilawaCupertinoWheelPicker)),
      );
      final tokens = theme.componentTokens.cupertinoWheelPicker;
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(TilawaCupertinoWheelPicker),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.height, tokens.pickerHeight);
      expect(tokens.pickerHeight, 200);
    });

    testWidgets('selection overlay uses translucent token color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themedApp(
          TilawaCupertinoWheelPicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2020, 1, 1, 9, 0),
            onDateTimeChanged: (_) {},
          ),
        ),
      );

      final theme = Theme.of(
        tester.element(find.byType(TilawaCupertinoWheelPicker)),
      );
      final overlay = tester.widget<CupertinoPickerDefaultSelectionOverlay>(
        find.byType(CupertinoPickerDefaultSelectionOverlay).first,
      );

      expect(overlay.background.a, lessThan(1.0));
      expect(
        overlay.background.a,
        theme.componentTokens.cupertinoWheelPicker.selectionOverlayColor.a,
      );
    });

    testWidgets('embeds CupertinoDatePicker', (tester) async {
      await tester.pumpWidget(
        _themedApp(
          TilawaCupertinoWheelPicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2020, 1, 1, 9, 0),
            onDateTimeChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });
  });
}
