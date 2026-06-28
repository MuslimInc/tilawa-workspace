import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void _expectMenuAnchoredBelowTrigger(WidgetTester tester) {
  final trigger = tester.getRect(find.byIcon(Icons.more_vert));
  final menuItem = tester.getRect(find.text('عرض التفاصيل'));

  expect(menuItem.top, greaterThan(trigger.bottom));
  expect(menuItem.left, lessThan(trigger.right));
  expect(menuItem.right, greaterThan(trigger.left));

  final menuCenterX = menuItem.center.dx;
  final triggerCenterX = trigger.center.dx;
  final screenCenterX = tester.view.physicalSize.width / 2;
  expect(
    (menuCenterX - triggerCenterX).abs(),
    lessThan((menuCenterX - screenCenterX).abs()),
  );
}

void main() {
  group('QuranSessionActionMenu', () {
    testWidgets('shows icon trigger only, not wrapped action text in Arabic', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionActionMenu(onViewDetails: () {}),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.text('عرض التفاصيل'), findsNothing);
      expect(find.text('عرض'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu opens near trigger, not centered on screen', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(24),
            child: QuranSessionActionMenu(
              onViewDetails: () {},
              onCancel: () {},
            ),
          ),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('عرض التفاصيل'), findsOneWidget);
      _expectMenuAnchoredBelowTrigger(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu items render without character wrapping at 360dp', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionActionMenu(
          onViewDetails: () {},
          onReschedule: () {},
          onCancel: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('عرض التفاصيل'), findsOneWidget);
      expect(find.text('إعادة الجدولة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu anchors correctly inside scrollable session card', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        ListView(
          children: [
            QuranSessionCard(
              session: makeSession(
                startsAt: DateTime.now().add(const Duration(days: 2)),
              ),
              now: DateTime.now(),
              variant: QuranSessionCardVariant.upcoming,
              onViewDetails: () {},
              onCancel: () {},
            ),
          ],
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      _expectMenuAnchoredBelowTrigger(tester);
    });

    testWidgets('trigger keeps 48dp touch target', (tester) async {
      await pumpInApp(
        tester,
        QuranSessionActionMenu(onViewDetails: () {}),
        surfaceSize: const Size(360, 800),
      );

      final triggerSize = tester.getSize(find.byType(IconButton));
      expect(triggerSize.width, 48);
      expect(triggerSize.height, 48);
    });
  });
}
