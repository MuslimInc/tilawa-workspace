import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('TilawaCheckbox enforces 48dp hit target on both axes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
        home: Scaffold(
          body: Center(
            child: TilawaCheckbox(value: true, onChanged: (_) {}),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(TilawaCheckbox));
    expect(size.width, kMeMuslimMinInteractiveDimension);
    expect(size.height, kMeMuslimMinInteractiveDimension);
  });

  testWidgets('TilawaCheckbox toggles when tapped', (tester) async {
    bool? value = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
        home: Scaffold(
          body: Center(
            child: TilawaCheckbox(
              value: value,
              onChanged: (next) => value = next,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TilawaCheckbox));
    await tester.pump();

    expect(value, isTrue);
  });
}
