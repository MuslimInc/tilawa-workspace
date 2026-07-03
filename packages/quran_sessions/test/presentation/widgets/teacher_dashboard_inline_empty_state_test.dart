import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_inline_empty_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/widget_pump.dart';

void main() {
  group('TeacherDashboardInlineEmptyState', () {
    testWidgets(
      'renders quiet start-aligned line without chrome when no icon given',
      (tester) async {
        await pumpInApp(
          tester,
          const Directionality(
            textDirection: TextDirection.rtl,
            child: TeacherDashboardInlineEmptyState(
              title: 'No upcoming sessions',
            ),
          ),
          textDirection: TextDirection.rtl,
        );

        expect(find.text('No upcoming sessions'), findsOneWidget);
        expect(find.byType(TilawaCard), findsNothing);
        expect(find.byType(TilawaIconBox), findsNothing);
        expect(
          find.descendant(
            of: find.byType(TeacherDashboardInlineEmptyState),
            matching: find.byType(DecoratedBox),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('renders subtitle when provided', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          title: 'No upcoming sessions',
          subtitle: 'Students will appear here once they book.',
        ),
      );

      expect(
        find.text('Students will appear here once they book.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders guidance container with quiet icon box when icon provided',
      (tester) async {
        await pumpInApp(
          tester,
          const TeacherDashboardInlineEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No bookable times this week',
            subtitle: 'Open days in your weekly schedule become times here.',
          ),
        );

        expect(find.byType(TilawaIconBox), findsOneWidget);
        expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
        expect(find.text('No bookable times this week'), findsOneWidget);
        expect(
          find.text('Open days in your weekly schedule become times here.'),
          findsOneWidget,
        );
        // Guidance weight stays a soft container, not a raised card.
        expect(find.byType(TilawaCard), findsNothing);
      },
    );
  });
}
