import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(() => TilawaInteractionFeedback.enabled = true);
  tearDown(() => TilawaInteractionFeedback.enabled = true);

  testWidgets(
    'TilawaInteractiveSurface survives disable while press in flight',
    (tester) async {
      var interactive = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: TilawaInteractiveSurface(
                    onTap: interactive ? () {} : null,
                    enabled: interactive,
                    child: const SizedBox(
                      key: Key('surface'),
                      width: 120,
                      height: 48,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('surface'))),
      );
      await tester.pump();

      interactive = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: TilawaInteractiveSurface(
                    onTap: interactive ? () {} : null,
                    enabled: interactive,
                    child: const SizedBox(
                      key: Key('surface'),
                      width: 120,
                      height: 48,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await gesture.up();
      await tester.pump();
    },
  );

  test('TilawaInteractionFeedback respects enabled flag', () {
    TilawaInteractionFeedback.enabled = false;
    expect(() {
      TilawaInteractionFeedback.trigger(TilawaHaptic.selection);
    }, returnsNormally);
  });
}
