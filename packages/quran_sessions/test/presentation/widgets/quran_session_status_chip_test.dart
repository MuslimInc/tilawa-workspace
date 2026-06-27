import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  group('QuranSessionStatusChip', () {
    const labelByLifecycle = <SessionLifecycleStatus, String>{
      SessionLifecycleStatus.scheduled: 'Scheduled',
      SessionLifecycleStatus.completed: 'Completed',
      SessionLifecycleStatus.cancelledByStudent: 'Cancelled',
    };

    labelByLifecycle.forEach((lifecycle, label) {
      testWidgets('renders "$label" for ${lifecycle.name}', (tester) async {
        await pumpInApp(
          tester,
          QuranSessionStatusChip(
            session: makeSession(lifecycleStatus: lifecycle),
          ),
          surfaceSize: const Size(360, 800),
        );

        expect(find.text(label), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('shows starting-soon label when joinable within window', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionStatusChip(
          session: makeSession(
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.now().add(const Duration(minutes: 10)),
          ),
          startsSoon: true,
        ),
        surfaceSize: const Size(360, 800),
      );

      expect(find.text('Starting soon'), findsOneWidget);
    });

    testWidgets('survives Arabic RTL at text scale 1.4 without overflow', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QuranSessionStatusChip(
          session: makeSession(
            lifecycleStatus: SessionLifecycleStatus.completed,
          ),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        textScaleFactor: 1.4,
        surfaceSize: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
