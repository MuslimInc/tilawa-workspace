import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_schedule_section.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_summary_stats.dart';

import '../../helpers/widget_pump.dart';

void main() {
  group('TeacherDashboardSummaryStats', () {
    testWidgets('renders three stat values in rtl order', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardSummaryStats(
          sectionTitle: 'نظرة سريعة',
          pendingRequestsCount: 2,
          upcomingSessionsCount: 5,
          bookableSlotsCount: 12,
          pendingRequestsLabel: 'طلبات معلقة',
          upcomingSessionsLabel: 'حصص قادمة',
          bookableSlotsLabel: 'مواعيد مفتوحة هذا الأسبوع',
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 190),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('طلبات معلقة'), findsOneWidget);
      expect(find.text('حصص قادمة'), findsOneWidget);
      expect(find.text('مواعيد مفتوحة هذا الأسبوع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('golden ar rtl summary stats row', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardSummaryStats(
          sectionTitle: 'نظرة سريعة',
          pendingRequestsCount: 1,
          upcomingSessionsCount: 3,
          bookableSlotsCount: 8,
          pendingRequestsLabel: 'طلبات معلقة',
          upcomingSessionsLabel: 'حصص قادمة',
          bookableSlotsLabel: 'مواعيد مفتوحة هذا الأسبوع',
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 190),
      );

      await expectLater(
        find.byType(TeacherDashboardSummaryStats),
        matchesGoldenFile('goldens/teacher_dashboard_summary_stats_ar.png'),
      );
    });
  });

  group('TeacherDashboardScheduleSection', () {
    testWidgets('schedule header action invokes callback', (tester) async {
      var tapped = false;

      await pumpInApp(
        tester,
        TeacherDashboardScheduleSection(
          actionLabel: 'Edit weekly template',
          onManageSchedule: () => tapped = true,
        ),
        locale: const Locale('en'),
        surfaceSize: const Size(390, 120),
      );

      await tester.tap(find.text('Edit weekly template'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('golden ar rtl schedule header action', (tester) async {
      await pumpInApp(
        tester,
        TeacherDashboardScheduleSection(
          actionLabel: 'تعديل الجدول الأسبوعي',
          onManageSchedule: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 120),
      );

      await expectLater(
        find.byType(TeacherDashboardScheduleSection),
        matchesGoldenFile('goldens/teacher_dashboard_schedule_section_ar.png'),
      );
    });
  });
}
