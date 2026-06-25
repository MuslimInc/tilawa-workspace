import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/atoms/tilawa_card.dart';
import '../../lib/src/atoms/tilawa_icon_box.dart';
import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';

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

void main() {
  group('TilawaCard onTap', () {
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
}
