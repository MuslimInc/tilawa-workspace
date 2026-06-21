import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/quran_sessions_form_field_shell.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('QuranSessionsFormFieldShell', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QuranSessionsFormFieldShell(
            prefixIcon: Icons.calendar_today_outlined,
            child: Text('12 June 2000'),
          ),
        ),
      );

      expect(find.text('12 June 2000'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          QuranSessionsFormFieldShell(
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
          const QuranSessionsFormFieldShell(
            prefixIcon: Icons.calendar_today_outlined,
            errorText: 'Date is required',
            child: Text('Pick a date'),
          ),
        ),
      );

      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('border radius comes from the chrome radius token', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuranSessionsFormFieldShell(child: Text('value'))),
      );

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final border = decorator.decoration.border! as OutlineInputBorder;
      final expected = TilawaDesignTokens.light().resolveRadius(
        family: TilawaRadiusFamily.chrome,
      );
      expect(border.borderRadius, BorderRadius.circular(expected));
    });

    testWidgets('keeps a >= 48dp hit target', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QuranSessionsFormFieldShell(
            onTap: () {},
            child: const Text('value'),
          ),
        ),
      );

      final size = tester.getSize(find.byType(InkWell));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('the shared decoration matches the widget border radius', (
      tester,
    ) async {
      late InputDecoration deco;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              deco = QuranSessionsFormFieldShell.decoration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final border = deco.border! as OutlineInputBorder;
      final expected = TilawaDesignTokens.light().resolveRadius(
        family: TilawaRadiusFamily.chrome,
      );
      expect(border.borderRadius, BorderRadius.circular(expected));
    });
  });
}
