import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/molecules/tilawa_alphabet_scrollbar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [TilawaDesignTokens.light(), TilawaComponentTokens.light()],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaAlphabetScrollbar', () {
    final letters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر'];

    testWidgets('renders all letters', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
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
          TilawaAlphabetScrollbar(
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
      final selections = <String?>[];

      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
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
      final selections = <String?>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
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
          TilawaAlphabetScrollbar(
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

    testWidgets('press shows overlay with selected letter immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('ج')),
      );
      await tester.pump();

      expect(find.text('ج'), findsWidgets);
      expect(
        find.byKey(const Key('alphabet_scrollbar_overlay')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('overlay is centered on screen', (tester) async {
      const screenWidth = 400.0;
      const screenHeight = 600.0;

      await tester.pumpWidget(
        SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _wrap(
            TilawaAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('ج')),
      );
      await tester.pump();

      final overlayElement = tester.element(
        find.byKey(const Key('alphabet_scrollbar_overlay')),
      );
      final overlaySize = Theme.of(
        overlayElement,
      ).componentTokens.alphabetScrollbar.overlaySize;
      final screenSize = MediaQuery.sizeOf(overlayElement);
      final expectedLeft = (screenSize.width - overlaySize) / 2;
      final expectedTop = (screenSize.height - overlaySize) / 2;

      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byKey(const Key('alphabet_scrollbar_overlay')),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.left, expectedLeft);
      expect(positioned.top, expectedTop);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('press move updates selected letter', (tester) async {
      final selections = <String?>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
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

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('ا')),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(selections.isNotEmpty, true);
    });

    testWidgets('scrolls to letter when selectedLetter changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        SizedBox(
          height: 100,
          child: _wrap(
            TilawaAlphabetScrollbar(
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

      await tester.pump();

      expect(find.byType(TilawaAlphabetScrollbar), findsOneWidget);
    });

    testWidgets('empty letters list renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
            letters: const [],
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      expect(find.byType(TilawaAlphabetScrollbar), findsOneWidget);
    });

    testWidgets('press callbacks select letter on release', (tester) async {
      final selections = <String?>[];

      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
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

    testWidgets('tap on already selected letter unselects it', (tester) async {
      String? selected = 'ب';

      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
            letters: letters,
            selectedLetter: selected,
            onLetterSelected: (letter) => selected = letter,
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('ب'));
      await tester.pump();

      expect(selected, isNull);
    });

    testWidgets(
      'tap on selected letter removes highlight immediately',
      (tester) async {
        String? selected = 'ب';

        Finder circleFor(String letter) => find.ancestor(
          of: find.text(letter),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return _wrap(
                TilawaAlphabetScrollbar(
                  letters: letters,
                  selectedLetter: selected,
                  onLetterSelected: (letter) =>
                      setState(() => selected = letter),
                  onPanUpdate: (_) {},
                  onPanStart: (_) {},
                  onPanEnd: (_) {},
                ),
              );
            },
          ),
        );

        expect(circleFor('ب'), findsOneWidget);

        await tester.tap(find.text('ب'));
        await tester.pump();

        expect(selected, isNull);
        expect(circleFor('ب'), findsNothing);
      },
    );

    testWidgets(
      'external clear of selectedLetter removes highlight immediately',
      (tester) async {
        String? currentLetter = 'ب';
        late StateSetter outerSetState;

        Finder circleFor(String letter) => find.ancestor(
          of: find.text(letter),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              outerSetState = setState;
              return _wrap(
                TilawaAlphabetScrollbar(
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

        expect(circleFor('ب'), findsOneWidget);

        outerSetState(() => currentLetter = null);
        await tester.pump();

        expect(circleFor('ب'), findsNothing);
      },
    );
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
                TilawaAlphabetScrollbar(
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
            TilawaAlphabetScrollbar(
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

    testWidgets('tap on whitespace below last letter selects last letter', (
      tester,
    ) async {
      String? selected;

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (letter) => selected = letter,
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      final scrollbarRect = tester.getRect(
        find.byType(TilawaAlphabetScrollbar),
      );

      final gesture = await tester.startGesture(
        Offset(scrollbarRect.center.dx, scrollbarRect.bottom - 8),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('alphabet_scrollbar_overlay')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      expect(selected, letters.last);
    });

    testWidgets('scrubbing uses rounded border on track without ClipRRect', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      final ThemeData theme = Theme.of(
        tester.element(find.byType(TilawaAlphabetScrollbar)),
      );
      final Finder trackFinder = find.descendant(
        of: find.byType(TilawaAlphabetScrollbar),
        matching: find.byType(AnimatedContainer),
      );

      expect(trackFinder, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TilawaAlphabetScrollbar),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );

      final BoxDecoration idleDecoration =
          (tester.widget<AnimatedContainer>(trackFinder).decoration
              as BoxDecoration);
      expect(idleDecoration.borderRadius, isNotNull);
      expect(
        idleDecoration.border!.top.width,
        theme.tokens.borderWidthThin,
      );
      expect(
        tester.widget<AnimatedContainer>(trackFinder).clipBehavior,
        Clip.antiAlias,
      );

      final Rect scrollbarRect = tester.getRect(
        find.byType(TilawaAlphabetScrollbar),
      );
      await tester.startGesture(scrollbarRect.center);
      await tester.pump();

      final BoxDecoration scrubDecoration =
          (tester.widget<AnimatedContainer>(trackFinder).decoration
              as BoxDecoration);
      expect(
        scrubDecoration.border!.top.width,
        theme.tokens.borderWidthThin * 2,
      );
      expect(
        scrubDecoration.border!.top.color,
        theme.colorScheme.primary.withValues(
          alpha: theme.tokens.opacityMedium,
        ),
      );
    });

    testWidgets('scrub into bottom of track selects last letter', (
      tester,
    ) async {
      final selections = <String?>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
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

      final scrollbarRect = tester.getRect(
        find.byType(TilawaAlphabetScrollbar),
      );

      final gesture = await tester.startGesture(
        Offset(scrollbarRect.center.dx, scrollbarRect.top + 10),
      );
      await tester.pump();

      await gesture.moveTo(
        Offset(scrollbarRect.center.dx, scrollbarRect.bottom - 8),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(selections.contains(letters.last), isTrue);
    });

    testWidgets('scrub into top of track selects first letter', (
      tester,
    ) async {
      final selections = <String?>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
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

      final scrollbarRect = tester.getRect(
        find.byType(TilawaAlphabetScrollbar),
      );

      final gesture = await tester.startGesture(
        Offset(scrollbarRect.center.dx, scrollbarRect.bottom - 10),
      );
      await tester.pump();

      await gesture.moveTo(
        Offset(scrollbarRect.center.dx, scrollbarRect.top + 8),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(selections.contains(letters.first), isTrue);
    });

    testWidgets('scrub continues when finger drifts horizontally off rail', (
      tester,
    ) async {
      final selections = <String?>[];

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
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

      final scrollbarRect = tester.getRect(
        find.byType(TilawaAlphabetScrollbar),
      );

      final gesture = await tester.startGesture(
        Offset(scrollbarRect.center.dx, scrollbarRect.top + 10),
      );
      await tester.pump();

      await gesture.moveTo(
        Offset(scrollbarRect.left - 40, scrollbarRect.bottom - 8),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(selections.contains(letters.last), isTrue);
    });

    testWidgets('overlay is dismissed after tap completes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
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
      await tester.pump();

      expect(find.byKey(const Key('alphabet_scrollbar_overlay')), findsNothing);
    });

    testWidgets('pointer cancel dismisses overlay immediately', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('د')),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(find.byKey(const Key('alphabet_scrollbar_overlay')), findsNothing);
    });

    testWidgets('overlay stays visible until pointer up', (tester) async {
      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: _wrap(
            TilawaAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('ث')),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('alphabet_scrollbar_overlay')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();
      expect(find.byKey(const Key('alphabet_scrollbar_overlay')), findsNothing);
    });

    testWidgets('disposing widget while overlay is showing does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaAlphabetScrollbar(
            letters: letters,
            selectedLetter: null,
            onLetterSelected: (_) {},
            onPanUpdate: (_) {},
            onPanStart: (_) {},
            onPanEnd: (_) {},
          ),
        ),
      );

      await tester.press(find.text('ت'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('distributes letters evenly across the full track height', (
      tester,
    ) async {
      const double trackHeight = 600;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: trackHeight,
            child: TilawaAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      final double itemExtent =
          theme.componentTokens.alphabetScrollbar.itemExtent;
      final double firstCenter = tester.getCenter(find.text('ا')).dy;
      final double secondCenter = tester.getCenter(find.text('ب')).dy;
      expect(secondCenter - firstCenter, closeTo(itemExtent, 1.0));
    });

    testWidgets('scrolls with fixed row height when letters overflow', (
      tester,
    ) async {
      final manyLetters = List.generate(
        30,
        (i) => String.fromCharCode('ا'.codeUnitAt(0) + i),
      );

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 220,
            child: TilawaAlphabetScrollbar(
              letters: manyLetters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('alphabet_scrollbar_scroll')),
        findsOneWidget,
      );

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      final double itemExtent =
          theme.componentTokens.alphabetScrollbar.itemExtent;
      final double firstCenter = tester
          .getCenter(find.text(manyLetters.first))
          .dy;
      final double secondCenter = tester
          .getCenter(find.text(manyLetters[1]))
          .dy;
      expect(secondCenter - firstCenter, closeTo(itemExtent, 1.0));

      final ScrollableState scrollable =
          tester.state(find.byType(Scrollable)) as ScrollableState;
      await scrollable.position.moveTo(scrollable.position.maxScrollExtent);
      await tester.pump();

      expect(
        scrollable.position.pixels,
        greaterThan(0),
      );
      expect(find.text(manyLetters.last), findsOneWidget);
    });

    testWidgets('rail scroll notifications do not propagate to ancestors', (
      tester,
    ) async {
      final manyLetters = List.generate(
        30,
        (i) => String.fromCharCode('ا'.codeUnitAt(0) + i),
      );
      var ancestorScrollNotifications = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          home: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              ancestorScrollNotifications++;
              return false;
            },
            child: Scaffold(
              body: SizedBox(
                height: 220,
                child: TilawaAlphabetScrollbar(
                  letters: manyLetters,
                  selectedLetter: null,
                  onLetterSelected: (_) {},
                  onPanUpdate: (_) {},
                  onPanStart: (_) {},
                  onPanEnd: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final ScrollableState railScrollable =
          tester.state(find.byType(Scrollable)) as ScrollableState;
      await railScrollable.position.moveTo(
        railScrollable.position.maxScrollExtent,
      );
      await tester.pump();

      expect(railScrollable.position.pixels, greaterThan(0));
      expect(ancestorScrollNotifications, 0);
    });

    testWidgets('didUpdateWidget keeps letters evenly distributed', (
      tester,
    ) async {
      final manyLetters = List.generate(
        30,
        (i) => String.fromCharCode('ا'.codeUnitAt(0) + i),
      );
      String? currentLetter = manyLetters.first;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            outerSetState = setState;
            return _wrap(
              SizedBox(
                height: 320,
                child: TilawaAlphabetScrollbar(
                  letters: manyLetters,
                  selectedLetter: currentLetter,
                  onLetterSelected: (_) {},
                  onPanUpdate: (_) {},
                  onPanStart: (_) {},
                  onPanEnd: (_) {},
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      outerSetState(() => currentLetter = manyLetters.last);
      await tester.pump();

      expect(find.text(manyLetters.last), findsOneWidget);
    });

    testWidgets('updates unselected letter colors when theme mode changes', (
      tester,
    ) async {
      const letters = ['A', 'B', 'C'];
      final ThemeData lightTheme = ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        extensions: [
          TilawaDesignTokens.light(),
          TilawaComponentTokens.light(),
        ],
      );
      final ThemeData darkTheme = ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        extensions: [
          TilawaDesignTokens.dark(),
          TilawaComponentTokens.dark(),
        ],
      );
      final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
        ThemeMode.dark,
      );

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, _) {
            return MaterialApp(
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: mode,
              home: Scaffold(
                body: SizedBox(
                  height: 400,
                  child: TilawaAlphabetScrollbar(
                    key: const ValueKey<String>('alphabet_scrollbar'),
                    letters: letters,
                    selectedLetter: null,
                    onLetterSelected: (_) {},
                    onPanUpdate: (_) {},
                    onPanStart: (_) {},
                    onPanEnd: (_) {},
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final Color darkColor = tester.widget<Text>(find.text('B')).style!.color!;

      themeMode.value = ThemeMode.light;
      await tester.pumpAndSettle();

      final Color lightColor = tester
          .widget<Text>(find.text('B'))
          .style!
          .color!;

      expect(darkColor, isNot(equals(lightColor)));
    });

    testWidgets('builds when resolved letter role has null fontSize', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              labelMedium: TextStyle(),
            ),
            extensions: [
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          home: Scaffold(
            body: TilawaAlphabetScrollbar(
              letters: letters,
              selectedLetter: null,
              onLetterSelected: (_) {},
              onPanUpdate: (_) {},
              onPanStart: (_) {},
              onPanEnd: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ا'), findsOneWidget);
    });
  });
}
