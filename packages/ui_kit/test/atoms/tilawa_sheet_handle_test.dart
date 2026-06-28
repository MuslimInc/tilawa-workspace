import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaSheetHandle', () {
    testWidgets('downward fling dismisses the modal route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        builder: (sheetContext) {
                          return const TilawaBottomSheetScaffold(
                            children: [Text('Sheet body')],
                          );
                        },
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet body'), findsOneWidget);

      await tester.fling(
        find.byType(TilawaSheetHandle),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Sheet body'), findsNothing);
    });

    testWidgets('custom onDismiss overrides Navigator.pop', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
          home: Scaffold(
            body: TilawaSheetHandle(
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.fling(
        find.byType(TilawaSheetHandle),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}
