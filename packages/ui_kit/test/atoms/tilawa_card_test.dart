import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

/// Card fixture with a trailing [IconButton] and blank [Text] body for taps.
Widget _cardWithNestedButton({
  required VoidCallback? onCardTap,
  required VoidCallback onButtonTap,
  Key? buttonKey,
}) {
  return SizedBox(
    width: 280,
    height: 120,
    child: TilawaCard(
      onTap: onCardTap,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Text('Blank body'),
          ),
          IconButton(
            key: buttonKey,
            onPressed: onButtonTap,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ),
  );
}

double _pressedStateLayerAlpha(WidgetTester tester) {
  final overlays = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(TilawaInteractiveSurface),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .where(
        (decoration) =>
            decoration.color != null &&
            decoration.color!.a > 0 &&
            decoration.border == null,
      );

  if (overlays.isEmpty) {
    return 0;
  }
  return overlays.first.color!.a;
}

void main() {
  setUp(() => TilawaInteractionFeedback.enabled = false);
  tearDown(() => TilawaInteractionFeedback.enabled = true);

  group('TilawaCard onTap — blank area', () {
    testWidgets('fires when tapping non-interactive decorated content', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 160,
            child: TilawaCard(
              onTap: () => tapped = true,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TilawaIconBox(
                    icon: Icons.wb_sunny_rounded,
                    backgroundColor: Colors.green.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 8),
                  const Text('Morning'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(tester.getCenter(find.byType(TilawaCard)));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('TilawaCard onTap — nested Material buttons', () {
    testWidgets('IconButton receives tap without firing card onTap', (
      WidgetTester tester,
    ) async {
      var cardTaps = 0;
      var buttonTaps = 0;
      const buttonKey = Key('nested-delete');

      await tester.pumpWidget(
        _wrap(
          _cardWithNestedButton(
            onCardTap: () => cardTaps++,
            onButtonTap: () => buttonTaps++,
            buttonKey: buttonKey,
          ),
        ),
      );

      await tester.tap(find.byKey(buttonKey));
      await tester.pump();

      expect(buttonTaps, 1);
      expect(cardTaps, 0);
    });

    testWidgets('blank body area still fires card onTap', (
      WidgetTester tester,
    ) async {
      var cardTaps = 0;
      var buttonTaps = 0;

      await tester.pumpWidget(
        _wrap(
          _cardWithNestedButton(
            onCardTap: () => cardTaps++,
            onButtonTap: () => buttonTaps++,
          ),
        ),
      );

      await tester.tap(find.text('Blank body'));
      await tester.pump();

      expect(cardTaps, 1);
      expect(buttonTaps, 0);
    });

    testWidgets('TextButton receives tap without firing card onTap', (
      WidgetTester tester,
    ) async {
      var cardTaps = 0;
      var buttonTaps = 0;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 280,
            height: 120,
            child: TilawaCard(
              onTap: () => cardTaps++,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Body')),
                  TextButton(
                    onPressed: () => buttonTaps++,
                    child: const Text('Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Action'));
      await tester.pump();

      expect(buttonTaps, 1);
      expect(cardTaps, 0);
    });

    testWidgets('nested InkWell on control does not fire card onTap', (
      WidgetTester tester,
    ) async {
      var cardTaps = 0;
      var inkWellTaps = 0;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 280,
            height: 120,
            child: TilawaCard(
              onTap: () => cardTaps++,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Blank')),
                  InkWell(
                    onTap: () => inkWellTaps++,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.settings),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(inkWellTaps, 1);
      expect(cardTaps, 0);

      await tester.tap(find.text('Blank'));
      await tester.pump();

      expect(cardTaps, 1);
    });
  });

  group('TilawaCard without onTap', () {
    testWidgets('nested IconButton is the only tappable target', (
      WidgetTester tester,
    ) async {
      var buttonTaps = 0;
      const buttonKey = Key('only-button');

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 280,
            height: 120,
            child: TilawaCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: IconButton(
                key: buttonKey,
                onPressed: () => buttonTaps++,
                icon: const Icon(Icons.star_outline),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TilawaInteractiveSurface), findsNothing);

      await tester.tap(find.byKey(buttonKey));
      await tester.pump();

      expect(buttonTaps, 1);
    });
  });

  group('TilawaCard — conflicting nested actions', () {
    testWidgets('nested delete IconButton fires only delete, not navigate', (
      WidgetTester tester,
    ) async {
      var navigated = false;
      var deleted = false;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 280,
            height: 120,
            child: TilawaCard(
              onTap: () => navigated = true,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(child: Text('Navigate me')),
                  IconButton(
                    onPressed: () => deleted = true,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(deleted, isTrue);
      expect(navigated, isFalse);
    });

    testWidgets('sibling Row pattern keeps actions independent', (
      WidgetTester tester,
    ) async {
      var navigated = false;
      var deleted = false;

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: TilawaCard(
                    onTap: () => navigated = true,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: const Text('Navigate me'),
                  ),
                ),
                IconButton(
                  onPressed: () => deleted = true,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      expect(deleted, isTrue);
      expect(navigated, isFalse);

      await tester.tap(find.text('Navigate me'));
      await tester.pump();
      expect(navigated, isTrue);
    });
  });

  group('TilawaCard pressed state feedback', () {
    // Nested controls inside a tappable card own their interaction area.
    // Enabled controls handle their own action; disabled controls become dead
    // zones. The parent card should only navigate and show press feedback from
    // blank/non-interactive card areas.

    testWidgets('whole card shows state layer on blank-area press', (
      WidgetTester tester,
    ) async {
      final tokens = MeMuslimDesignTokens.light();

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 120,
            child: TilawaCard(
              onTap: () {},
              backgroundColor: Colors.white,
              child: const Text('Press me'),
            ),
          ),
        ),
      );

      expect(_pressedStateLayerAlpha(tester), 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Press me')),
      );
      await tester.pump();

      expect(_pressedStateLayerAlpha(tester), tokens.stateLayerPressed);

      await gesture.up();
      await tester.pump();

      expect(_pressedStateLayerAlpha(tester), 0);
    });

    testWidgets(
      'card does not show pressed wash when pressing nested IconButton',
      (
        WidgetTester tester,
      ) async {
        const buttonKey = Key('scale-button');

        await tester.pumpWidget(
          _wrap(
            _cardWithNestedButton(
              onCardTap: () {},
              onButtonTap: () {},
              buttonKey: buttonKey,
            ),
          ),
        );

        expect(_pressedStateLayerAlpha(tester), 0);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(buttonKey)),
        );
        await tester.pump();

        expect(_pressedStateLayerAlpha(tester), 0);

        await gesture.up();
        await tester.pump();
      },
    );

    testWidgets(
      'nested IconButton tap fires button only without card pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;
        var buttonTaps = 0;
        const buttonKey = Key('nested-scale-button');

        await tester.pumpWidget(
          _wrap(
            _cardWithNestedButton(
              onCardTap: () => cardTaps++,
              onButtonTap: () => buttonTaps++,
              buttonKey: buttonKey,
            ),
          ),
        );

        expect(_pressedStateLayerAlpha(tester), 0);

        await tester.tap(find.byKey(buttonKey));
        await tester.pump();

        expect(buttonTaps, 1);
        expect(cardTaps, 0);
        expect(_pressedStateLayerAlpha(tester), 0);
      },
    );

    testWidgets(
      'nested InkWell tap fires control only without card pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;
        var inkWellTaps = 0;

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 280,
              height: 120,
              child: TilawaCard(
                onTap: () => cardTaps++,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Blank')),
                    InkWell(
                      onTap: () => inkWellTaps++,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(_pressedStateLayerAlpha(tester), 0);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.settings)),
        );
        await tester.pump();

        expect(_pressedStateLayerAlpha(tester), 0);

        await gesture.up();
        await tester.pump();

        expect(inkWellTaps, 1);
        expect(cardTaps, 0);
      },
    );

    testWidgets('blank body tap fires card onTap and shows pressed wash', (
      WidgetTester tester,
    ) async {
      var cardTaps = 0;

      await tester.pumpWidget(
        _wrap(
          _cardWithNestedButton(
            onCardTap: () => cardTaps++,
            onButtonTap: () {},
          ),
        ),
      );

      final tokens = MeMuslimDesignTokens.light();

      await tester.pumpWidget(
        _wrap(
          _cardWithNestedButton(
            onCardTap: () => cardTaps++,
            onButtonTap: () {},
          ),
        ),
      );

      expect(_pressedStateLayerAlpha(tester), 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Blank body')),
      );
      await tester.pump();

      expect(_pressedStateLayerAlpha(tester), tokens.stateLayerPressed);

      await gesture.up();
      await tester.pump();

      expect(cardTaps, 1);
      expect(_pressedStateLayerAlpha(tester), 0);
    });

    testWidgets('custom corner radius paints state layer with matching shape', (
      WidgetTester tester,
    ) async {
      const radius = 24.0;
      final tokens = MeMuslimDesignTokens.light();

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 120,
            child: TilawaCard(
              onTap: () {},
              borderRadius: radius,
              backgroundColor: Colors.white,
              child: const Text('Rounded'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Rounded')),
      );
      await tester.pump();

      expect(_pressedStateLayerAlpha(tester), tokens.stateLayerPressed);

      final wash = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(TilawaInteractiveSurface),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .firstWhere(
            (decoration) =>
                decoration.color != null &&
                decoration.color!.a > 0 &&
                decoration.border == null,
          );

      expect(wash.borderRadius, BorderRadius.circular(radius));

      await gesture.up();
      await tester.pump();
    });
  });

  group('TilawaCard nested interaction regions', () {
    // Nested controls inside a tappable card own their interaction area.
    // Enabled controls handle their own action; disabled controls become dead
    // zones. The parent card should only navigate and show press feedback from
    // blank/non-interactive card areas.

    testWidgets(
      'enabled nested IconButton blocks parent onTap and pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;
        var buttonTaps = 0;
        const buttonKey = Key('enabled-region-button');

        await tester.pumpWidget(
          _wrap(
            _cardWithNestedButton(
              onCardTap: () => cardTaps++,
              onButtonTap: () => buttonTaps++,
              buttonKey: buttonKey,
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(buttonKey)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(_pressedStateLayerAlpha(tester), 0);

        await gesture.up();
        await tester.pump();

        expect(buttonTaps, 1);
        expect(cardTaps, 0);
        expect(_pressedStateLayerAlpha(tester), 0);
      },
    );

    testWidgets(
      'disabled nested IconButton blocks parent onTap and pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;
        const buttonKey = Key('disabled-region-button');

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 280,
              height: 120,
              child: TilawaCard(
                onTap: () => cardTaps++,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(child: Text('Blank body')),
                    IconButton(
                      key: buttonKey,
                      onPressed: null,
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(buttonKey)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(_pressedStateLayerAlpha(tester), 0);

        await gesture.up();
        await tester.pump();

        expect(cardTaps, 0);
        expect(_pressedStateLayerAlpha(tester), 0);
      },
    );

    testWidgets(
      'disabled nested TextButton blocks parent onTap and pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 280,
              height: 120,
              child: TilawaCard(
                onTap: () => cardTaps++,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(child: Text('Blank body')),
                    TextButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Action')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(_pressedStateLayerAlpha(tester), 0);

        await gesture.up();
        await tester.pump();

        expect(cardTaps, 0);
        expect(_pressedStateLayerAlpha(tester), 0);
      },
    );

    testWidgets(
      'null-callback InkWell lets parent receive tap and pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 280,
              height: 120,
              child: TilawaCard(
                onTap: () => cardTaps++,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Expanded(child: Text('Blank body')),
                    InkWell(
                      onTap: null,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final tokens = MeMuslimDesignTokens.light();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.settings)),
        );
        await tester.pump();

        expect(
          _pressedStateLayerAlpha(tester),
          tokens.stateLayerPressed,
        );
        await gesture.up();
        await tester.pump();

        expect(cardTaps, 1);
        expect(_pressedStateLayerAlpha(tester), 0);
      },
    );

    testWidgets(
      'handler-less GestureDetector lets parent receive tap and pressed wash',
      (WidgetTester tester) async {
        var cardTaps = 0;

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 280,
              height: 120,
              child: TilawaCard(
                onTap: () => cardTaps++,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Blank body')),
                    GestureDetector(
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.star_outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final tokens = MeMuslimDesignTokens.light();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.star_outline)),
        );
        await tester.pump();

        expect(
          _pressedStateLayerAlpha(tester),
          tokens.stateLayerPressed,
        );
        await gesture.up();
        await tester.pump();

        expect(cardTaps, 1);
        expect(_pressedStateLayerAlpha(tester), 0);
      },
    );

    testWidgets(
      'parent card onTap null does not show pressed wash on blank area',
      (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            const SizedBox(
              width: 280,
              height: 120,
              child: TilawaCard(
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(16),
                child: Text('Static body'),
              ),
            ),
          ),
        );

        expect(find.byType(TilawaInteractiveSurface), findsNothing);

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Static body')),
        );
        await tester.pump();

        expect(_pressedStateLayerAlpha(tester), 0);

        await gesture.up();
        await tester.pump();
      },
    );
  });
}
