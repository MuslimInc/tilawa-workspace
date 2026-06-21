import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_field_shell.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_input_style.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_search_field.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaFieldShell', () {
    testWidgets('search shell is the sole OutlineInputBorder owner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaSearchField(
            hintText: 'Search',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(OutlineInputBorder), findsNothing);
      expect(find.byType(TilawaFieldShell), findsOneWidget);
    });

    testWidgets('decorator shell renders InputDecorator with child', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              final style = context.inputStyle();
              return TilawaFieldShell.decorator(
                decoration: style.decoration(hintText: 'Pick'),
                child: const Text('Value'),
              );
            },
          ),
        ),
      );

      expect(find.text('Value'), findsOneWidget);
      expect(find.byType(InputDecorator), findsOneWidget);
    });

    testWidgets('search field does not paint a nested Material outline', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: Builder(
              builder: (context) {
                final style = context.inputStyle(role: TilawaInputRole.search);
                return TilawaFieldShell.search(
                  style: style,
                  isFocused: false,
                  hasError: false,
                  child: TextField(
                    controller: controller,
                    decoration: style.borderlessDecoration(
                      hintText: 'Search reciters',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final deco = textField.decoration!;
      expect(deco.enabledBorder, InputBorder.none);
      expect(deco.focusedBorder, InputBorder.none);

      final shell = tester.widget<TilawaFieldShell>(
        find.byType(TilawaFieldShell),
      );
      expect(shell.style, isNotNull);
    });
  });
}
