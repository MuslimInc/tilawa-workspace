import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import 'teacher_join_navigation_test_bloc.dart';

QuranSession _inAppUpcomingSession() {
  final start = DateTime.now().add(const Duration(minutes: 5));
  return QuranSession(
    id: 'session_join',
    bookingId: 'booking_1',
    teacherId: 'teacher_1',
    studentId: 'student_1',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    callType: SessionCallType.voiceCall,
    status: QuranSessionStatus.scheduled,
    lifecycleStatus: SessionLifecycleStatus.scheduled,
    callProviderKind: SessionCallProviderKind.mock,
  );
}

class _NoOpCallControlGateway implements SessionCallControlGateway {
  @override
  Future<void> leave() async {}

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {}

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {}

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {}

  @override
  Future<void> switchCamera() async {}
}

Future<void> _pumpTeacherDashboard(
  WidgetTester tester, {
  required TeacherDashboardBloc bloc,
  Future<bool?> Function(String bookingId)? onSessionDetailRequested,
  QuranSessionsAnalyticsCallbacks analytics =
      const QuranSessionsAnalyticsCallbacks(),
}) async {
  tester.view.physicalSize = const Size(390, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: const Locale('en'),
      localizationsDelegates: const [
        ...QuranSessionsLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      builder: (context, child) => TilawaFeedbackHost(child: child!),
      home: BlocProvider<TeacherDashboardBloc>.value(
        value: bloc,
        child: TeacherDashboardScreen(
          teacherId: 'teacher_1',
          analytics: analytics,
          onSessionDetailRequested: onSessionDetailRequested,
          createCallControlGateway: (_) => _NoOpCallControlGateway(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openUpcomingCategory(WidgetTester tester) async {
  final l10n = QuranSessionsLocalizations.of(
    tester.element(find.byType(TeacherDashboardScreen)),
  );
  await tester.tap(find.text(l10n.upcomingSessionsSectionTitle).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('en');
  });

  testWidgets('dashboard join opens call shell without opening detail', (
    tester,
  ) async {
    String? openedBookingId;
    final sessionRepo = FakeSessionRepository();
    final scheduleRepo = FakeScheduleRepository();
    final bloc = TeacherJoinNavigationTestBloc(
      seed: seedTeacherDashboardSuccess(
        upcomingSessions: [_inAppUpcomingSession()],
      ),
      sessionRepo: sessionRepo,
      scheduleRepo: scheduleRepo,
    );

    await _pumpTeacherDashboard(
      tester,
      bloc: bloc,
      onSessionDetailRequested: (bookingId) async {
        openedBookingId = bookingId;
        return null;
      },
    );

    await _openUpcomingCategory(tester);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    check(openedBookingId).isNull();
    expect(find.byKey(const Key('call_shell_end')), findsOneWidget);
  });

  testWidgets('invokes onSessionJoined after successful dashboard join', (
    tester,
  ) async {
    String? joinedBookingId;
    String? joinedSessionId;
    final sessionRepo = FakeSessionRepository();
    final scheduleRepo = FakeScheduleRepository();
    final bloc = TeacherJoinNavigationTestBloc(
      seed: seedTeacherDashboardSuccess(
        upcomingSessions: [_inAppUpcomingSession()],
      ),
      sessionRepo: sessionRepo,
      scheduleRepo: scheduleRepo,
    );

    await _pumpTeacherDashboard(
      tester,
      bloc: bloc,
      analytics: QuranSessionsAnalyticsCallbacks(
        onSessionJoined: ({bookingId, sessionId}) {
          joinedBookingId = bookingId;
          joinedSessionId = sessionId;
        },
      ),
    );

    await _openUpcomingCategory(tester);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    check(joinedBookingId).equals('booking_1');
    check(joinedSessionId).equals('session_join');
  });
}
