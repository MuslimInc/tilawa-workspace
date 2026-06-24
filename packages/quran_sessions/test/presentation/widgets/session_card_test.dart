import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  group('SessionCard', () {
    testWidgets('renders teacher name and a status chip', (tester) async {
      await pumpInApp(
        tester,
        SessionCard(
          session: makeSession(),
          teacherName: 'Sheikh Ahmed',
        ),
        surfaceSize: const Size(420, 320),
      );

      expect(find.text('Sheikh Ahmed'), findsOneWidget);
      expect(find.byType(TilawaStatusChip), findsOneWidget);
    });

    testWidgets('omits the teacher name when not provided', (tester) async {
      await pumpInApp(
        tester,
        SessionCard(session: makeSession()),
        surfaceSize: const Size(420, 320),
      );

      expect(find.text('Sheikh Ahmed'), findsNothing);
    });

    const expectedLabels = <QuranSessionStatus, String>{
      QuranSessionStatus.scheduled: 'Scheduled',
      QuranSessionStatus.inProgress: 'In progress',
      QuranSessionStatus.completed: 'Completed',
      QuranSessionStatus.cancelledByStudent: 'Cancelled',
      QuranSessionStatus.cancelledByTeacher: 'Cancelled',
      QuranSessionStatus.noShow: 'No-show',
    };

    for (final entry in expectedLabels.entries) {
      testWidgets('status badge shows "${entry.value}" for ${entry.key.name}', (
        tester,
      ) async {
        await pumpInApp(
          tester,
          SessionCard(session: makeSession(status: entry.key)),
          surfaceSize: const Size(420, 320),
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('tapping the card invokes onTap', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        SessionCard(session: makeSession(), onTap: () => taps++),
        surfaceSize: const Size(420, 320),
      );

      await tester.tap(find.byType(TilawaCard));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('no action row when neither join nor cancel provided', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        SessionCard(session: makeSession()),
        surfaceSize: const Size(420, 320),
      );

      expect(find.byType(TilawaButton), findsNothing);
    });

    testWidgets('join and cancel actions render and fire callbacks', (
      tester,
    ) async {
      var joins = 0;
      var cancels = 0;
      await pumpInApp(
        tester,
        SessionCard(
          session: makeSession(),
          onJoin: () => joins++,
          onCancel: () => cancels++,
        ),
        surfaceSize: const Size(420, 320),
      );

      expect(find.text('Join'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Join'));
      await tester.pump();
      expect(joins, 1);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancels, 1);
    });
  });
}
