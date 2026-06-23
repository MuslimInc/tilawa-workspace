import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/widgets/deferred_after_first_frame.dart';

void main() {
  testWidgets('DeferredAfterFirstFrame shows placeholder then child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeferredAfterFirstFrame(
          placeholder: Text('placeholder'),
          child: Text('content'),
        ),
      ),
    );

    expect(find.text('placeholder'), findsOneWidget);
    expect(find.text('content'), findsNothing);

    await tester.pump();

    expect(find.text('placeholder'), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });
}
