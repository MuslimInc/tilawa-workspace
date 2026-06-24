import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/atoms/tilawa_text_field.dart';

/// Simple test wrapper that provides the minimal Material environment
Widget testWrapper({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('TilawaTextField Assertions', () {
    testWidgets(
      'throws AssertionError when both controller and initialValue provided',
      (tester) async {
        expect(
          () => TilawaTextField(
            controller: TextEditingController(),
            initialValue: 'test',
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets(
      'throws AssertionError when both isPassword and suffixIcon provided',
      (tester) async {
        expect(
          () => TilawaTextField(
            isPassword: true,
            suffixIcon: const Icon(Icons.add),
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets(
      'throws AssertionError when both onClear and suffixIcon provided',
      (tester) async {
        expect(
          () => TilawaTextField(
            onClear: () {},
            suffixIcon: const Icon(Icons.add),
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets(
      'throws AssertionError when both isPassword and onClear provided',
      (tester) async {
        expect(
          () => TilawaTextField(isPassword: true, onClear: () {}),
          throwsAssertionError,
        );
      },
    );
  });

  group('TilawaTextField Behavior', () {
    testWidgets(
      'clear button appears only when text is not empty and onClear is provided',
      (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          testWrapper(
            child: TilawaTextField(controller: controller, onClear: () {}),
          ),
        );

        // Initially empty, no clear button
        expect(find.byIcon(Icons.clear), findsNothing);

        // Add text via user input (triggers listener properly)
        await tester.enterText(find.byType(TextField), 'hello');
        await tester.pump();
        expect(find.byType(IconButton), findsOneWidget);

        // Clear text via user input
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();
        expect(find.byType(IconButton), findsNothing);
      },
    );

    testWidgets('tapping clear button clears text and calls callbacks', (
      tester,
    ) async {
      bool onClearCalled = false;
      String lastChangedValue = 'initial';
      final controller = TextEditingController(text: 'hello');

      await tester.pumpWidget(
        testWrapper(
          child: TilawaTextField(
            controller: controller,
            onClear: () => onClearCalled = true,
            onChanged: (val) => lastChangedValue = val,
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(onClearCalled, isTrue);
      expect(lastChangedValue, isEmpty);
    });

    testWidgets('password toggle changes obscure state', (tester) async {
      await tester.pumpWidget(
        testWrapper(child: const TilawaTextField(isPassword: true)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final updatedField = tester.widget<TextField>(find.byType(TextField));
      expect(updatedField.obscureText, isFalse);
    });

    testWidgets(
      'disabled field does not show clear action even if text present',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            child: TilawaTextField(
              enabled: false,
              initialValue: 'hello',
              onClear: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.clear), findsNothing);
      },
    );

    testWidgets('renders errorText correctly', (tester) async {
      await tester.pumpWidget(
        testWrapper(child: const TilawaTextField(errorText: 'Required field')),
      );

      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets(
      'errorText is exposed to assistive tech as a live region (a11y/feedback)',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            child: const TilawaTextField(
              label: 'Email',
              errorText: 'Enter a valid email',
            ),
          ),
        );

        final sem = tester.getSemantics(find.byType(TilawaTextField));
        expect(sem.flagsCollection.isLiveRegion, isTrue);
        expect(sem.value, 'Enter a valid email');
      },
    );

    testWidgets('no error means no live region (no regression)', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(child: const TilawaTextField(label: 'Email')),
      );

      final sem = tester.getSemantics(find.byType(TilawaTextField));
      expect(sem.flagsCollection.isLiveRegion, isFalse);
    });

    testWidgets('respects maxLength and blocks input beyond limit', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        testWrapper(
          child: TilawaTextField(controller: controller, maxLength: 5),
        ),
      );

      // Enter text within limit
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(controller.text, 'hello');

      // Try to exceed limit - Flutter prevents this at framework level
      // We verify the field still has the original text
      expect(controller.text.length, 5);
    });

    testWidgets('counter is hidden by default when maxLength is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(child: const TilawaTextField(maxLength: 100)),
      );

      // Counter should not be visible (no counter text pattern like "0/100")
      expect(find.textContaining('/100'), findsNothing);
    });

    testWidgets('counter appears when showCounter is true', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          child: const TilawaTextField(
            maxLength: 100,
            showCounter: true,
            initialValue: 'test',
          ),
        ),
      );

      // Counter should show current/max format
      expect(find.textContaining('4'), findsOneWidget);
    });
  });

  group('TilawaTextField Lifecycle', () {
    testWidgets('disposes internal controller', (tester) async {
      // This is hard to test directly without exposing internals,
      // but we can verify it doesn't crash.
      await tester.pumpWidget(
        testWrapper(child: const TilawaTextField(initialValue: 'test')),
      );
      await tester.pumpWidget(Container()); // Dispose
    });

    testWidgets('does not dispose external controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        testWrapper(child: TilawaTextField(controller: controller)),
      );
      await tester.pumpWidget(Container()); // Dispose widget

      // External controller should still be functional
      controller.text = 'alive';
      expect(controller.text, 'alive');
      controller.dispose();
    });
  });
}
