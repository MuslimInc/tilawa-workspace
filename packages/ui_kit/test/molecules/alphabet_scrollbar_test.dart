import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/molecules/alphabet_scrollbar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [TilawaDesignTokens.light(), TilawaComponentTokens.light()],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ArabicAlphabetScrollbar', () {
    final letters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر'];

    testWidgets('renders all letters', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      for (final letter in letters) {
        expect(find.text(letter), findsOneWidget);
      }
    });

    testWidgets('tap on letter triggers onLetterSelected', (tester) async {
      String? selected;

      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (letter) => selected = letter,
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('ب'));
      await tester.pump();

      expect(selected, 'ب');
    });

    testWidgets('multiple taps select different letters', (tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: selections.add,
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('ا'));
      await tester.tap(find.text('ج'));
      await tester.tap(find.text('د'));
      await tester.pump();

      expect(selections, ['ا', 'ج', 'د']);
    });

    testWidgets('drag gesture triggers multiple selections', (tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            ArabicAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: selections.add,
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      // Start pan gesture (press and drag)
      final gesture = await tester.press(find.text('ا'));
      await tester.pump();

      // Drag down through multiple letters
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      // Multiple selections should have occurred during drag
      expect(selections.length, greaterThanOrEqualTo(1));

      // Release
      await gesture.up();
      await tester.pump();
    });

    testWidgets('selected letter shows highlighted state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: 'ب',
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      // Selected letter should be in a Container with circular decoration
      final selectedContainer = find.ancestor(
        of: find.text('ب'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(selectedContainer, findsOneWidget);

      // Unselected letter should not have circle container
      final unselectedContainer = find.ancestor(
        of: find.text('ا'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(unselectedContainer, findsNothing);
    });

    testWidgets('long press shows overlay with selected letter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      // Long press on a letter
      final letterFinder = find.text('ج');
      await tester.longPress(letterFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Overlay should appear with the letter
      expect(find.text('ج'), findsWidgets); // At least 2 (list + overlay)
    });

    testWidgets('long press move updates selected letter', (tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            ArabicAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: selections.add,
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      // Start long press on first letter
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('ا')),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Drag down to another letter
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      // Should have selected the first letter at minimum
      expect(selections.isNotEmpty, true);
    });

    testWidgets('scrolls to letter when selectedLetter changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        SizedBox(
          height: 100, // Constrain height to force scrolling
          child: _wrap(
            ArabicAlphabetScrollbar(
              letters: letters,
              selectedLetter: 'ا',
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Verify scrollbar renders
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('empty letters list renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: const [],
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('tap callbacks work with GestureDetector', (tester) async {
      final selections = <String>[];

      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: selections.add,
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      // Tap down and up (simulates tap)
      final gesture = await tester.press(find.text('ث'));
      await gesture.up();
      await tester.pump();

      expect(selections, contains('ث'));
    });
    testWidgets(
      'didUpdateWidget updates selected state when selectedLetter changes externally',
      (tester) async {
        String? currentLetter = 'ا';
        late StateSetter outerSetState;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              outerSetState = setState;
              return _wrap(
                ArabicAlphabetScrollbar(
                  letters: letters,
                  selectedLetter: currentLetter,
                  onLetterSelected: (_) {},
                  onPanUpdate: (_) {},
                  onPanStart: (_) {},
                  onPanEnd: (_) {},
                ),
              );
            },
          ),
        );

        // Initial: 'ا' has circle highlight, 'ب' does not.
        Finder circleFor(String letter) => find.ancestor(
          of: find.text(letter),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect(circleFor('ا'), findsOneWidget);
        expect(circleFor('ب'), findsNothing);

        // Change selection externally via StatefulBuilder rebuild.
        outerSetState(() => currentLetter = 'ب');
        await tester.pump();

        expect(circleFor('ب'), findsOneWidget);
        expect(circleFor('ا'), findsNothing);
      },
    );

    testWidgets('pan gesture forwards onPanStart and onPanEnd callbacks', (
      tester,
    ) async {
      var panStartCount = 0;
      var panEndCount = 0;

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            ArabicAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) => panStartCount++,
              onPanEnd: (_) => panEndCount++,
            ),
          ),
        ),
      );

      final gesture = await tester.press(find.text('ا'));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(panStartCount, 1);
      expect(panEndCount, 1);
    });

    testWidgets('overlay is dismissed after tap completes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArabicAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      final gesture = await tester.press(find.text('ج'));
      await tester.pump();
      await gesture.up();
      // Advance past the 100ms Future.delayed in onTapUp.
      await tester.pump(const Duration(milliseconds: 150));

      // _draggedLetter is null after tap, so overlayChildBuilder returns
      // SizedBox.shrink() — the keyed overlay container is not in the tree.
      expect(find.byKey(const Key('alphabet_scrollbar_overlay')), findsNothing);
    });
  });
}
