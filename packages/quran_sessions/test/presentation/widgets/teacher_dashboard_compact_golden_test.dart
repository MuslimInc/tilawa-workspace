import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/src/domain/entities/session_lifecycle_status.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_inline_empty_state.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_dashboard_section.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_session_compact_card.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  group('Teacher dashboard compact goldens', () {
    testWidgets('section header ar rtl', (tester) async {
      await pumpInApp(
        tester,
        const TutorDashboardSection(title: 'طلبات الحجز'),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 150),
      );

      await expectLater(
        find.byType(TutorDashboardSection),
        matchesGoldenFile('goldens/teacher_dashboard_section_ar.png'),
      );
    });

    testWidgets('secondary section header without schedule action ar rtl', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const TutorDashboardSection(
          title: 'المواعيد القابلة للحجز',
          variant: TutorDashboardSectionVariant.secondary,
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 150),
      );

      await expectLater(
        find.byType(TutorDashboardSection),
        matchesGoldenFile('goldens/teacher_dashboard_section_secondary_ar.png'),
      );
    });

    testWidgets('inline empty pending ar rtl', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          title: 'لا توجد طلبات حجز حاليًا',
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 150),
      );

      await expectLater(
        find.byType(TeacherDashboardInlineEmptyState),
        matchesGoldenFile('goldens/teacher_dashboard_empty_pending_ar.png'),
      );
    });

    testWidgets('inline empty upcoming ar rtl', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          title: 'لا توجد حصص قادمة',
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 150),
      );

      await expectLater(
        find.byType(TeacherDashboardInlineEmptyState),
        matchesGoldenFile('goldens/teacher_dashboard_empty_upcoming_ar.png'),
      );
    });

    testWidgets('inline empty bookable ar rtl', (tester) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          title: 'لا توجد مواعيد قابلة للحجز هذا الأسبوع.',
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 120),
      );

      await expectLater(
        find.byType(TeacherDashboardInlineEmptyState),
        matchesGoldenFile('goldens/teacher_dashboard_empty_bookable_ar.png'),
      );
    });

    testWidgets('pending session card ar rtl', (tester) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        startsAt: DateTime(2026, 7, 15, 14, 0),
      );

      await pumpInApp(
        tester,
        TutorSessionCompactCard(
          session: session,
          studentDisplayName: 'فاطمة علي',
          now: DateTime(2026, 7, 14, 10),
          onAccept: () {},
          onReject: () {},
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 140),
      );

      await expectLater(
        find.byType(TutorSessionCompactCard),
        matchesGoldenFile('goldens/teacher_dashboard_pending_card_ar.png'),
      );
    });

    testWidgets('upcoming session card join not yet ar rtl', (tester) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.scheduled,
        startsAt: DateTime(2026, 7, 20, 16, 0),
        endsAt: DateTime(2026, 7, 20, 17, 0),
      );

      await pumpInApp(
        tester,
        TutorSessionCompactCard(
          session: session,
          studentDisplayName: 'عمر حسن',
          now: DateTime(2026, 7, 14, 10),
          onJoin: () {},
          onCancel: () {},
          showCancelInOverflowMenu: true,
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 150),
      );

      await expectLater(
        find.byType(TutorSessionCompactCard),
        matchesGoldenFile('goldens/teacher_dashboard_upcoming_card_ar.png'),
      );
    });

    testWidgets('pending card text scale 1.4 ar rtl', (tester) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        startsAt: DateTime(2026, 7, 15, 14, 0),
      );

      await pumpInApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: TutorSessionCompactCard(
            session: session,
            studentDisplayName: 'فاطمة علي',
            now: DateTime(2026, 7, 14, 10),
            onAccept: () {},
            onReject: () {},
          ),
        ),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        surfaceSize: const Size(390, 168),
      );

      await expectLater(
        find.byType(TutorSessionCompactCard),
        matchesGoldenFile(
          'goldens/teacher_dashboard_pending_card_ar_scale_1_4.png',
        ),
      );
    });
  });
}
