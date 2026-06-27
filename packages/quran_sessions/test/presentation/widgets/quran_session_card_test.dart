import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  group('QuranSessionCard', () {
    testWidgets('upcoming session shows join now when join window is open', (
      tester,
    ) async {
      var joined = false;
      final start = DateTime.now().add(const Duration(minutes: 5));

      await pumpInApp(
        tester,
        QuranSessionCard(
          session: makeSession(
            startsAt: start,
            endsAt: start.add(const Duration(hours: 1)),
          ),
          now: DateTime.now(),
          variant: QuranSessionCardVariant.upcoming,
          onJoin: () => joined = true,
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('Join now'), findsOneWidget);
      await tester.tap(find.text('Join now'));
      await tester.pump();
      expect(joined, isTrue);
    });

    testWidgets('past session hides join and cancel buttons', (tester) async {
      await pumpInApp(
        tester,
        QuranSessionCard(
          session: makeSession(status: QuranSessionStatus.completed),
          now: DateTime.now(),
          variant: QuranSessionCardVariant.past,
          onViewDetails: () {},
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('Join'), findsNothing);
      expect(find.text('Join now'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('View details'), findsOneWidget);
    });

    testWidgets('cancel action is available from overflow menu', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionCard(
          session: makeSession(
            startsAt: DateTime.now().add(const Duration(days: 2)),
          ),
          now: DateTime.now(),
          variant: QuranSessionCardVariant.upcoming,
          onCancel: () {},
        ),
        surfaceSize: const Size(360, 800),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Cancel session'), findsOneWidget);
    });

    testWidgets('compact card avoids horizontal overflow at 360dp', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionCard(
          session: makeSession(
            startsAt: DateTime.now().add(const Duration(hours: 2)),
          ),
          now: DateTime.now(),
          teacherName: 'الشيخ محمد بن عبد الله الطويل',
          variant: QuranSessionCardVariant.upcoming,
          onViewDetails: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('compact card stays readable at text scale 1.4', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionCard(
          session: makeSession(
            startsAt: DateTime.now().add(const Duration(minutes: 10)),
          ),
          now: DateTime.now(),
          teacherName: 'الشيخ محمد بن عبد الله كامل الهاشمي الطويل جدًا',
          variant: QuranSessionCardVariant.upcoming,
          onJoin: () {},
          onViewDetails: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        textScaleFactor: 1.4,
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('انضم الآن'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
