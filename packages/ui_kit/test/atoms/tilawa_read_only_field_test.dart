import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/atoms/tilawa_read_only_field.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('TilawaReadOnlyField', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaReadOnlyField(
            prefixIcon: Icons.calendar_today_outlined,
            onTap: () {},
            child: const Text('12 June 2000'),
          ),
        ),
      );

      expect(find.text('12 June 2000'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          TilawaReadOnlyField(
            prefixIcon: Icons.calendar_today_outlined,
            onTap: () => tapped = true,
            child: const Text('Pick a date'),
          ),
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows the error text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaReadOnlyField(
            prefixIcon: Icons.calendar_today_outlined,
            onTap: () {},
            errorText: 'Date is required',
            child: const Text('Pick a date'),
          ),
        ),
      );

      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('border radius comes from the chrome radius token', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaReadOnlyField(onTap: () {}, child: const Text('value')),
        ),
      );

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final border = decorator.decoration.border! as OutlineInputBorder;
      final expected = MeMuslimDesignTokens.light().resolveRadius(
        family: TilawaRadiusFamily.chrome,
      );
      expect(border.borderRadius, BorderRadius.circular(expected));
    });

    testWidgets('keeps a >= 48dp hit target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaReadOnlyField(
            onTap: () {},
            child: const Text('value'),
          ),
        ),
      );

      final size = tester.getSize(find.byType(InkWell));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
