import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../rtl_test_matrix.dart';

Widget _themedApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaPickerSegmentCard', () {
    testInBothDirections('selected card uses token border color', (
      tester,
      direction,
    ) async {
      await pumpWithDirection(
        tester,
        _themedApp(
          TilawaPickerSegmentCard(
            label: 'Start',
            value: '9:00 AM',
            selected: true,
            onTap: () {},
          ),
        ),
        direction,
      );

      final theme = Theme.of(tester.element(find.text('Start')));
      final tokens = theme.componentTokens.cupertinoWheelPicker;
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TilawaPickerSegmentCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, tokens.segmentSelectedBackgroundColor);
      expect(
        decoration.border!.top.color,
        tokens.segmentSelectedBorderColor,
      );
    });

    testWidgets('unselected card uses unselected token colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themedApp(
          TilawaPickerSegmentCard(
            label: 'End',
            value: '5:00 PM',
            selected: false,
            onTap: () {},
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.text('End')));
      final tokens = theme.componentTokens.cupertinoWheelPicker;
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TilawaPickerSegmentCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, tokens.segmentUnselectedBackgroundColor);
      expect(
        decoration.border!.top.color,
        tokens.segmentUnselectedBorderColor,
      );
    });

    testWidgets('tap invokes onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _themedApp(
          TilawaPickerSegmentCard(
            label: 'Start',
            value: '9:00',
            selected: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(TilawaPickerSegmentCard));
      expect(tapped, isTrue);
    });
  });
}
