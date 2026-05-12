import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [TilawaDesignTokens.light(), TilawaComponentTokens.light()],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaIllustratedState', () {
    testWidgets('renders custom visual, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            visual: SizedBox(
              key: ValueKey('state_visual'),
              width: 64,
              height: 64,
            ),
            title: 'No downloads yet',
            subtitle: 'Save recitations for offline listening.',
          ),
        ),
      );

      expect(find.byKey(const ValueKey('state_visual')), findsOneWidget);
      expect(find.text('No downloads yet'), findsOneWidget);
      expect(
        find.text('Save recitations for offline listening.'),
        findsOneWidget,
      );
    });

    testWidgets('renders icon fallback when visual is not provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.download_done_rounded,
            title: 'Ready offline',
          ),
        ),
      );

      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
      expect(find.text('Ready offline'), findsOneWidget);
    });

    testWidgets('renders and triggers primary and secondary actions', (
      tester,
    ) async {
      var primaryTapCount = 0;
      var secondaryTapCount = 0;

      await tester.pumpWidget(
        _wrap(
          TilawaIllustratedState(
            icon: Icons.search_off_rounded,
            title: 'No results',
            primaryAction: TextButton(
              onPressed: () => primaryTapCount += 1,
              child: const Text('Clear search'),
            ),
            secondaryAction: TextButton(
              onPressed: () => secondaryTapCount += 1,
              child: const Text('Browse all'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear search'));
      await tester.tap(find.text('Browse all'));
      await tester.pump();

      expect(primaryTapCount, 1);
      expect(secondaryTapCount, 1);
    });

    testWidgets('applies semantic label to the state container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.explore_outlined,
            title: 'Calibrate Qibla',
            semanticLabel: 'Qibla calibration required',
          ),
        ),
      );

      final stateSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Qibla calibration required',
      );
      expect(stateSemantics, findsOneWidget);
    });

    testWidgets('uses provided maximum width', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaIllustratedState(
            icon: Icons.favorite_border_rounded,
            title: 'No favorites',
            maxWidth: 280,
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('No favorites'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );

      expect(constrainedBox.constraints.maxWidth, 280);
    });
  });
}
