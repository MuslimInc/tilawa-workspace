import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/src/domain/entities/quran_session.dart';
import 'package:quran_sessions/src/domain/entities/session_call_type.dart';
import 'package:quran_sessions/src/domain/entities/session_lifecycle_status.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_dashboard_inline_empty_state.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_session_compact_card.dart';
import 'package:quran_sessions/src/presentation/widgets/tutor_session_status_chip.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/widget_pump.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: const [
        ...QuranSessionsLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('TutorSessionCompactCard', () {
    testWidgets('pending request shows accept and decline actions', (
      tester,
    ) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
      );

      await tester.pumpWidget(
        wrap(
          TutorSessionCompactCard(
            session: session,
            studentDisplayName: 'Fatima Ali',
            now: DateTime.now(),
            onAccept: () {},
            onReject: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Fatima Ali'), findsOneWidget);
    });

    testWidgets('upcoming session shows join and overflow cancel', (
      tester,
    ) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.scheduled,
        startsAt: DateTime.now().add(const Duration(minutes: 20)),
      );

      await tester.pumpWidget(
        wrap(
          TutorSessionCompactCard(
            session: session,
            studentDisplayName: 'Omar Hassan',
            now: DateTime.now(),
            onJoin: () {},
            onCancel: () {},
            showCancelInOverflowMenu: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('join disabled before window with not-yet hint', (
      tester,
    ) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.scheduled,
        startsAt: DateTime.now().add(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        wrap(
          TutorSessionCompactCard(
            session: session,
            studentDisplayName: 'Sara',
            now: DateTime.now(),
            onJoin: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join is not open yet'), findsOneWidget);
      final joinFinder = find.widgetWithText(TilawaButton, 'Join');
      expect(joinFinder, findsOneWidget);
      final joinButton = tester.widget<TilawaButton>(joinFinder);
      check(joinButton.onPressed).isNull();
    });

    testWidgets('voice and video icons render for call types', (tester) async {
      final voice = makeSession(
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        startsAt: DateTime.now().add(const Duration(days: 1)),
      );
      final videoSession = QuranSession(
        id: voice.id,
        bookingId: voice.bookingId,
        teacherId: voice.teacherId,
        studentId: voice.studentId,
        startsAt: voice.startsAt,
        endsAt: voice.endsAt,
        callType: SessionCallType.videoCall,
        status: voice.status,
        lifecycleStatus: voice.lifecycleStatus,
      );

      await tester.pumpWidget(
        wrap(
          TutorSessionCompactCard(
            session: videoSession,
            studentDisplayName: 'Student',
            now: DateTime.now(),
            onAccept: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    });
  });

  group('TutorSessionStatusChip', () {
    testWidgets('pending approval label in Arabic RTL', (tester) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
      );

      await tester.pumpWidget(
        wrap(
          Directionality(
            textDirection: TextDirection.rtl,
            child: TutorSessionStatusChip(session: session),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('بانتظار موافقتك'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepted label for scheduled session', (tester) async {
      final session = makeSession(
        lifecycleStatus: SessionLifecycleStatus.scheduled,
      );

      await tester.pumpWidget(
        wrap(TutorSessionStatusChip(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accepted'), findsOneWidget);
    });
  });

  group('TeacherDashboardInlineEmptyState compact', () {
    testWidgets('renders single-line empty title without large card', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const TeacherDashboardInlineEmptyState(
          icon: Icons.event_note_outlined,
          title: 'No upcoming sessions',
        ),
      );

      expect(find.text('No upcoming sessions'), findsOneWidget);
      expect(find.byType(TilawaCard), findsOneWidget);
    });
  });

  testWidgets('multiple compact cards fit without vertical overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final sessions = List.generate(
      4,
      (i) => makeSession(
        id: 'session_$i',
        lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        startsAt: DateTime.now().add(Duration(hours: i + 1)),
      ),
    );

    await tester.pumpWidget(
      wrap(
        ListView(
          children: [
            for (final session in sessions)
              TutorSessionCompactCard(
                session: session,
                studentDisplayName: 'Student ${session.id}',
                now: DateTime.now(),
                onAccept: () {},
                onReject: () {},
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TutorSessionCompactCard), findsNWidgets(4));
  });
}
