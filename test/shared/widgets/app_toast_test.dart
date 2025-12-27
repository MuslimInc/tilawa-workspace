import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/app_toast.dart';

void main() {
  testWidgets('AppToast shows message and dismisses after duration', (
    tester,
  ) async {
    const message = 'Test Toast Message';
    const duration = Duration(seconds: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppToast.show(context, message: message, duration: duration);
                },
                child: const Text('Show Toast'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to show toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump(); // Start animation/overlay

    // Verify toast is visible
    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    // Wait for duration
    await tester.pump(duration);
    await tester.pump(); // Process timer callback removal

    // Verify toast receives removal (might take frame or two)
    await tester.pumpAndSettle();

    // Verify toast is gone
    expect(find.text(message), findsNothing);
  });
}
