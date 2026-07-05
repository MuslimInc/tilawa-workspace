import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import 'my_sessions_join_navigation_test_bloc.dart';

QuranSession _inAppSession({
  SessionCallProviderKind providerKind = SessionCallProviderKind.mock,
}) {
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
    callProviderKind: providerKind,
  );
}

Future<void> _pumpMySessionsScreen(
  WidgetTester tester, {
  required MySessionsBloc bloc,
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
      localizationsDelegates: QuranSessionsLocalizations.localizationsDelegates,
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      builder: (context, child) => TilawaFeedbackHost(child: child!),
      home: BlocProvider<MySessionsBloc>.value(
        value: bloc,
        child: MySessionsScreen(
          studentId: 'student_1',
          analytics: analytics,
          createCallControlGateway: (_) => _NoOpCallControlGateway(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invokes onMySessionsOpened once when the screen opens', (
    tester,
  ) async {
    var openedCount = 0;
    final bloc = MySessionsJoinNavigationTestBloc(
      seed: const MySessionsSuccess(upcoming: [], past: []),
    );

    await _pumpMySessionsScreen(
      tester,
      bloc: bloc,
      analytics: QuranSessionsAnalyticsCallbacks(
        onMySessionsOpened: () => openedCount++,
      ),
    );

    expect(openedCount, 1);
  });

  testWidgets('invokes onSessionJoined with ids after a successful join', (
    tester,
  ) async {
    String? joinedBookingId;
    String? joinedSessionId;
    final bloc = MySessionsJoinNavigationTestBloc(
      seed: MySessionsSuccess(
        upcoming: [_inAppSession(providerKind: SessionCallProviderKind.mock)],
        past: const [],
      ),
    );

    await _pumpMySessionsScreen(
      tester,
      bloc: bloc,
      analytics: QuranSessionsAnalyticsCallbacks(
        onSessionJoined: ({bookingId, sessionId}) {
          joinedBookingId = bookingId;
          joinedSessionId = sessionId;
        },
      ),
    );

    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();

    expect(joinedBookingId, 'booking_1');
    expect(joinedSessionId, 'session_join');
  });

  testWidgets('in-app join from list opens call shell', (tester) async {
    final bloc = MySessionsJoinNavigationTestBloc(
      seed: MySessionsSuccess(
        upcoming: [_inAppSession(providerKind: SessionCallProviderKind.mock)],
        past: const [],
      ),
    );

    await _pumpMySessionsScreen(tester, bloc: bloc);

    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('call_shell_end')), findsOneWidget);
  });

  testWidgets('external join shows pre-join sheet before dispatching join', (
    tester,
  ) async {
    final bloc = MySessionsJoinNavigationTestBloc(
      seed: MySessionsSuccess(
        upcoming: [
          makeSession(
            id: 'session_join',
            studentId: 'student_1',
            startsAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
        ],
        past: const [],
      ),
    );

    await _pumpMySessionsScreen(tester, bloc: bloc);

    await tester.tap(find.text('Join now'));
    await tester.pumpAndSettle();

    expect(find.text('Join outside MeMuslim?'), findsOneWidget);
    expect(find.text('Leave call'), findsNothing);
  });
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
