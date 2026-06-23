import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/atoms/tilawa_button.dart';
import '../../lib/src/foundation/app_colors.dart';
import '../../lib/src/foundation/app_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/foundation/tilawa_icons.dart';
import '../../lib/src/foundation/tilawa_dialog.dart';

Widget _host(void Function(BuildContext) onPressed) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('confirm dialog shows title, message, and stacked actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        (context) => showTilawaConfirmDialog(
          context: context,
          title: 'Log out',
          message: 'Are you sure you want to log out?',
          confirmLabel: 'Log out',
          cancelLabel: 'Cancel',
          onConfirm: () {},
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    // Title + confirm button both read "Log out".
    expect(find.text('Log out'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);
    // Close affordance from the title row.
    expect(find.byIcon(TilawaIcons.dismiss), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('Close')),
      const Size.square(kTilawaMinInteractiveDimension),
    );
  });

  testWidgets(
    'confirm dialog pops with true and fires onConfirm once when primary '
    'tapped',
    (tester) async {
      var confirmCount = 0;
      bool? result;
      await tester.pumpWidget(
        _host((context) async {
          result = await showTilawaConfirmDialog(
            context: context,
            title: 'Delete',
            message: 'This cannot be undone.',
            confirmLabel: 'Delete',
            onConfirm: () => confirmCount++,
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // The confirm button is the only "Delete" inside a TilawaButton.
      await tester.tap(find.widgetWithText(TilawaButton, 'Delete'));
      await tester.pumpAndSettle();

      // Dialog dismissed itself exactly once; the underlying screen remains.
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(result, isTrue);
      expect(confirmCount, 1);
    },
  );

  testWidgets('cancel dismisses the confirm dialog without confirming', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      _host(
        (context) => showTilawaConfirmDialog(
          context: context,
          title: 'Delete',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
          onConfirm: () => confirmed = true,
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TilawaButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('picker dialog renders its body and title', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => showTilawaPickerDialog<void>(
          context: context,
          title: 'Choose theme',
          bodyBuilder: (_) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Light'), Text('Dark')],
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });
}
