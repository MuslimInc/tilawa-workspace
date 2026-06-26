import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_inline_empty_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

void main() {
  group('TeacherDashboardInlineEmptyState', () {
    testWidgets('renders title and icon, hides optional subtitle/action', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No upcoming sessions',
        ),
      );

      expect(find.text('No upcoming sessions'), findsOneWidget);
      expect(find.byType(TilawaIconBox), findsOneWidget);
      expect(find.byType(TilawaCard), findsOneWidget);
      expect(find.byType(TilawaButton), findsNothing);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No upcoming sessions',
          subtitle: 'Students will appear here once they book.',
        ),
      );

      expect(
        find.text('Students will appear here once they book.'),
        findsOneWidget,
      );
    });

    testWidgets('shows action and invokes onAction when both provided', (
      tester,
    ) async {
      var taps = 0;
      await pumpInApp(
        tester,
        TeacherDashboardInlineEmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No availability',
          actionLabel: 'Set availability',
          onAction: () => taps++,
          iconTone: TilawaStateVisualTone.error,
        ),
      );

      expect(find.text('Set availability'), findsOneWidget);
      await tester.tap(find.text('Set availability'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('hides action when label given without callback', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No availability',
          actionLabel: 'Set availability',
        ),
      );

      expect(find.byType(TilawaButton), findsNothing);
    });
  });
}
