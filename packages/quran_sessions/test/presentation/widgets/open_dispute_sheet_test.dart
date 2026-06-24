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
        onPressed: () async => results.add(await showOpenDisputeSheet(context)),
        child: const Text('open'),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
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
      await tester.tap(find.text('Submit dispute'));
      await tester.pumpAndSettle();

      expect(find.byType(TilawaBottomSheetScaffold), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('returns the trimmed reason when valid', (tester) async {
      final results = await _openSheet(tester);

      await tester.enterText(find.byType(TextField), '  unfair charge  ');
      await tester.tap(find.text('Submit dispute'));
      await tester.pumpAndSettle();

      expect(results, <String>['unfair charge']);
    });

    testWidgets('cancel closes the sheet with a null result', (tester) async {
      final results = await _openSheet(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(results, <String?>[null]);
    });
  });
}
