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

  testWidgets(
    'showing a new toast cancels the previous timer and removes old toast',
    (tester) async {
      // This test covers lines 20-21: _timer?.cancel() and _currentEntry?.remove()
      const firstMessage = 'First Toast';
      const secondMessage = 'Second Toast';
      const duration = Duration(seconds: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        AppToast.show(
                          context,
                          message: firstMessage,
                        );
                      },
                      child: const Text('Show First'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        AppToast.show(
                          context,
                          message: secondMessage,
                        );
                      },
                      child: const Text('Show Second'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Show first toast
      await tester.tap(find.text('Show First'));
      await tester.pump();

      // Verify first toast is visible
      expect(find.text(firstMessage), findsOneWidget);

      // Show second toast before the first one times out
      // This triggers lines 20-21
      await tester.tap(find.text('Show Second'));
      await tester.pump();

      // First toast should be removed and second toast should be visible
      expect(find.text(firstMessage), findsNothing);
      expect(find.text(secondMessage), findsOneWidget);

      // Wait for duration to let second toast disappear
      await tester.pump(duration);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify second toast is gone
      expect(find.text(secondMessage), findsNothing);
    },
  );
}
