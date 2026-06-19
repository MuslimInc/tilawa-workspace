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
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaIconBox tinted variant', () {
    testWidgets('uses semantic tint fill without border', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const TilawaIconBox(
            icon: Icons.menu_book_outlined,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.scholar,
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(TilawaIconBox));
      final colorScheme = Theme.of(context).colorScheme;
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TilawaIconBox),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(
        decoration.color,
        colorScheme.semanticTintBackground(
          TilawaSemanticTint.scholar,
        ),
      );
      expect(decoration.border, isNull);
    });
  });
}
