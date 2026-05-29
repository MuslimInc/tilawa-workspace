import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/presentation/widgets/athkar_category_card.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart' show AppTheme;

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required VoidCallback onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: AthkarCategoryCard(
                name: 'Morning',
                icon: 'wb_sunny_rounded',
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AthkarCategoryCard', () {
    testWidgets('invokes onTap when the card body is tapped', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await pumpCard(tester, onTap: () => tapped = true);

      await tester.tapAt(tester.getCenter(find.byType(AthkarCategoryCard)));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('invokes onTap when tapping the icon area', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await pumpCard(tester, onTap: () => tapped = true);

      final Rect card = tester.getRect(find.byType(AthkarCategoryCard));
      await tester.tapAt(
        Offset(card.center.dx, card.top + card.height * 0.35),
      );
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
