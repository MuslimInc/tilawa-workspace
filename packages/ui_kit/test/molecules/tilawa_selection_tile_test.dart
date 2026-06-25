import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaSelectionTile', () {
    testWidgets('selected row meets minimum interactive height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaSelectionTile(
            title: 'A',
            isSelected: true,
            onTap: () {},
            showDivider: false,
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(TilawaSelectionTile),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(
        constrainedBox.constraints.minHeight,
        kMeMuslimMinInteractiveDimension,
      );
    });

    testWidgets('selected checkmark uses primary color for hierarchy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaSelectionTile(
            title: 'Selected option',
            isSelected: true,
            onTap: () {},
            showDivider: false,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(TilawaIcons.check));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(icon.color, theme.colorScheme.primary);
    });
  });
}
