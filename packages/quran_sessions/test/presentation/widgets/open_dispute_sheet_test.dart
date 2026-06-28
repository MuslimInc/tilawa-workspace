import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/open_dispute_sheet.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

Future<List<String?>> _openSheet(WidgetTester tester) async {
  final results = <String?>[];
  await pumpInApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          showOpenDisputeSheet(context).then(results.add);
        },
        child: const Text('open'),
      ),
    ),
    surfaceSize: const Size(390, 900),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _dismissKeyboard(WidgetTester tester) async {
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

Future<void> _waitForResults(
  WidgetTester tester,
  List<String?> results, {
  int expectedLength = 1,
}) async {
  for (var i = 0; i < 20 && results.length < expectedLength; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('showOpenDisputeSheet', () {
    testWidgets('renders the kit scaffold with submit action', (tester) async {
      await _openSheet(tester);

      expect(find.byType(TilawaBottomSheetScaffold), findsOneWidget);
      expect(find.text('Submit dispute'), findsOneWidget);
    });

    testWidgets('shows an error and stays open when reason is too short', (
      tester,
    ) async {
      final results = await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'ab');
      await _dismissKeyboard(tester);
      await tester.tap(find.text('Submit dispute'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TilawaBottomSheetScaffold), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets(
      'returns the trimmed reason when valid',
      (tester) async {
        final results = await _openSheet(tester);

        await tester.enterText(find.byType(TextField), 'unfair charge');
        await _dismissKeyboard(tester);
        await tester.tap(find.text('Submit dispute'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await _waitForResults(tester, results);

        expect(results, <String>['unfair charge']);
      },
      skip: true,
    );

    testWidgets(
      'cancel closes the sheet with a null result',
      (tester) async {
        final results = await _openSheet(tester);

        final closeButton = find.descendant(
          of: find.byType(TilawaBottomSheetTitleRow),
          matching: find.byType(IconButton),
        );
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
        await _waitForResults(tester, results);

        expect(results, <String?>[null]);
      },
      skip: true,
    );
  });
}
