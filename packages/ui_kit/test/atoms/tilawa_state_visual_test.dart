import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: brightness,
  );
  final designTokens = brightness == Brightness.dark
      ? TilawaDesignTokens.dark()
      : TilawaDesignTokens.light();
  final componentTokens = brightness == Brightness.dark
      ? TilawaComponentTokens.dark(colorScheme: colorScheme)
      : TilawaComponentTokens.light(colorScheme: colorScheme);

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [designTokens, componentTokens],
    ),
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('TilawaStateVisual', () {
    testWidgets('renders the centered icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaStateVisual(icon: Icons.download_done_rounded)),
      );

      expect(find.byType(TilawaStateVisual), findsOneWidget);
      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
    });

    testWidgets('uses the provided size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaStateVisual(
            icon: Icons.explore_rounded,
            size: 120,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byIcon(Icons.explore_rounded),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.width, 120);
      expect(sizedBox.height, 120);
    });

    testWidgets('applies semantic label when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaStateVisual(
            icon: Icons.location_off_rounded,
            semanticLabel: 'Location needed',
          ),
        ),
      );

      final semantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Location needed',
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('uses accent color for the icon by default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaStateVisual(
            icon: Icons.error_outline_rounded,
            accentColor: Colors.red,
          ),
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(icon.color, Colors.red);
    });

    testWidgets('resolves tone color from the active color scheme', (
      tester,
    ) async {
      final colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      );

      await tester.pumpWidget(
        _wrap(
          const TilawaStateVisual(
            icon: Icons.error_outline_rounded,
            tone: TilawaStateVisualTone.error,
          ),
          brightness: Brightness.dark,
        ),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(icon.color, colorScheme.error);
    });

    testWidgets('renders in RTL without layout exceptions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaStateVisual(
            icon: Icons.explore_off_rounded,
            tone: TilawaStateVisualTone.tertiary,
          ),
          textDirection: TextDirection.rtl,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.explore_off_rounded), findsOneWidget);
    });
  });
}
