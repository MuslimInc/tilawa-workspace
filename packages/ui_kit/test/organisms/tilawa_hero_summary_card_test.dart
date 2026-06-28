import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF219653),
  );

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaHeroSummaryCard', () {
    testWidgets('renders label, metric, badges, and footer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const TilawaHeroSummaryCard(
            label: 'Pages read this week',
            metric: '42',
            badges: [
              TilawaHeroSummaryBadge(
                label: '+3 today',
                icon: Icons.trending_up,
                tint: TilawaSemanticTint.ink,
              ),
            ],
            footer: SizedBox(
              key: Key('hero_footer'),
              height: 48,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      );

      expect(find.text('Pages read this week'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+3 today'), findsOneWidget);
      expect(find.byKey(const Key('hero_footer')), findsOneWidget);
    });

    testWidgets('uses tokenized hub card surface treatment', (
      WidgetTester tester,
    ) async {
      final ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF219653),
      );
      final designTokens = MeMuslimDesignTokens.light();
      final componentTokens = MeMuslimComponentTokens.light(
        colorScheme: colorScheme,
      );

      await tester.pumpWidget(
        _app(
          const TilawaHeroSummaryCard(
            label: 'Pages read this week',
            metric: '42',
          ),
        ),
      );

      final BoxDecoration cardDecoration = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.color == colorScheme.surface);

      expect(cardDecoration.color, colorScheme.surface);
      expect(
        cardDecoration.borderRadius,
        BorderRadius.circular(
          designTokens.resolveRadius(family: TilawaRadiusFamily.hero),
        ),
      );
      expect(
        cardDecoration.border,
        Border.all(
          color: componentTokens.settingsGroup.groupContainerBorderColor,
          width: componentTokens.settingsGroup.tileDividerThickness,
        ),
      );
    });

    testWidgets('progress footer clamps value and uses semantic fill', (
      WidgetTester tester,
    ) async {
      final ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF219653),
      );

      await tester.pumpWidget(
        _app(
          const TilawaHeroSummaryProgress(
            label: 'Weekly goal',
            valueLabel: '120%',
            progress: 1.4,
            tint: TilawaSemanticTint.success,
          ),
        ),
      );

      final progressFill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      final fillColors = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((widget) => widget.color);

      expect(find.text('Weekly goal'), findsOneWidget);
      expect(find.text('120%'), findsOneWidget);
      expect(progressFill.widthFactor, 1);
      expect(
        fillColors,
        contains(
          colorScheme.semanticTintForeground(TilawaSemanticTint.success),
        ),
      );
    });
  });
}
