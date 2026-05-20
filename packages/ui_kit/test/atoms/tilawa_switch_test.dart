import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('TilawaSwitch enforces 48dp hit target on both axes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
        home: Scaffold(
          body: Center(
            child: TilawaSwitch(value: true, onChanged: (_) {}),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(TilawaSwitch));
    expect(size.width, kTilawaMinInteractiveDimension);
    expect(size.height, kTilawaMinInteractiveDimension);
  });
}
