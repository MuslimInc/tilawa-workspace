import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaChip', () {
    testWidgets('long label in equal-width columns does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TilawaChip(
                    label: 'Unavailable (day off)',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TilawaChip(
                    label: 'Custom hours',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Unavailable (day off)'), findsOneWidget);
      expect(find.text('Custom hours'), findsOneWidget);
    });

    testWidgets('label-only chip in Wrap stays compact', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: Wrap(
              spacing: 8,
              children: [
                TilawaChip(label: 'Saturday', onTap: () {}),
                TilawaChip(label: 'Sunday', onTap: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final Size first = tester.getSize(find.text('Saturday'));
      final Size second = tester.getSize(find.text('Sunday'));
      expect(first.width, lessThan(120));
      expect(second.width, lessThan(120));
    });

    testWidgets('icon and long label ellipsize inside bounded width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 120,
            child: TilawaChip(
              label: 'Unavailable (day off)',
              icon: Icons.event_busy_outlined,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final paragraph = tester.widget<Text>(find.byType(Text));
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.maxLines, 1);
    });
  });
}
