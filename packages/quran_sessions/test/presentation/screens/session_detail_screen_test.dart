import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import 'join_loading_hold_bloc.dart';
import 'join_navigation_test_bloc.dart';
import 'recording_session_detail_bloc.dart';
import 'review_emit_bloc.dart';
import 'session_detail_event_recorder.dart';
import 'tutor_cancel_emit_success_bloc.dart';

Future<void> _pumpSessionDetailScreen(
  WidgetTester tester, {
  required SessionDetailBloc bloc,
  SessionCallControlGatewayFactory? createCallControlGateway,
  void Function({required int surahNumber, int? ayahNumber})?
  onPracticeRevisionRequested,
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
      localizationsDelegates: const [
        QuranSessionsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      builder: (context, child) => TilawaFeedbackHost(child: child!),
      home: BlocProvider<SessionDetailBloc>.value(
        value: bloc,
        child: SessionDetailScreen(
          bookingId: 'session_1',
          analytics: analytics,
          createCallControlGateway: createCallControlGateway,
          onPracticeRevisionRequested: onPracticeRevisionRequested,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SessionDetailSuccess _inAppJoinSeed({
  SessionCallProviderKind callProviderKind = SessionCallProviderKind.mock,
}) {
  final startsAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
  final aggregate = makeAggregate(
    status: SessionLifecycleStatus.confirmed,
    startsAt: startsAt,
  ).copyWith(sessionId: 'session_1');

  return SessionDetailSuccess(
    aggregate: aggregate,
    timeline: const [],
    callProviderKind: callProviderKind,
  );
}

SessionDetailSuccess _externalJoinSeed({required String meetingUrl}) {
  final startsAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
  final aggregate = makeAggregate(
    status: SessionLifecycleStatus.confirmed,
    startsAt: startsAt,
  ).copyWith(sessionId: 'session_1');

  return SessionDetailSuccess(
    aggregate: aggregate,
    timeline: const [],
    externalMeetingJoinUrl: meetingUrl,
  );
}

void main() {
  testWidgets('pre-join sheet shows Open and Copy URL buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bloc = RecordingSessionDetailBloc(
      seed: _externalJoinSeed(meetingUrl: 'https://meet.google.com/room'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<SessionDetailBloc>.value(
          value: bloc,
          child: const SessionDetailScreen(bookingId: 'session_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Copy URL'), findsOneWidget);
  });

  testWidgets('pre-join sheet shows before join for external sessions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final recorder = SessionDetailEventRecorder();
    final bloc = RecordingSessionDetailBloc(
      seed: _externalJoinSeed(meetingUrl: 'https://meet.google.com/room'),
      onRecord: recorder.record,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<SessionDetailBloc>.value(
          value: bloc,
          child: const SessionDetailScreen(bookingId: 'session_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('Join outside MeMuslim?'), findsOneWidget);
    expect(
      recorder.events.whereType<SessionDetailJoinRequested>(),
      isEmpty,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      recorder.events.whereType<SessionDetailJoinRequested>(),
      hasLength(1),
    );
  });

  testWidgets('join action stays in bottom action area', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final startsAt = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
      startsAt: startsAt,
    ).copyWith(sessionId: 'session_1');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<SessionDetailBloc>(
          create: (_) => RecordingSessionDetailBloc(
            seed: SessionDetailSuccess(
              aggregate: aggregate,
              timeline: const [],
            ),
          ),
          child: const SessionDetailScreen(bookingId: 'session_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TilawaBottomActionArea), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
  });

  testWidgets(
    'bottom action area is not rendered when no actions are available',
    (tester) async {
      final aggregate = makeAggregate(
        status: SessionLifecycleStatus.incomplete,
        startsAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      ).copyWith(sessionId: 'session_1');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<SessionDetailBloc>(
            create: (_) => RecordingSessionDetailBloc(
              seed: SessionDetailSuccess(
                aggregate: aggregate,
                timeline: const [],
              ),
            ),
            child: const SessionDetailScreen(bookingId: 'session_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TilawaBottomActionArea), findsNothing);
    },
  );

  testWidgets('join button stays visible with loading while preparing', (
    tester,
  ) async {
    final bloc = JoinLoadingHoldBloc(seed: _inAppJoinSeed());

    await _pumpSessionDetailScreen(tester, bloc: bloc);

    await tester.tap(find.text('Join'));
    await tester.pump();

    final joinButton = tester.widget<TilawaButton>(
      find.byWidgetPredicate(
        (widget) => widget is TilawaButton && widget.text == 'Join',
      ),
    );
    check(joinButton.isLoading).isTrue();
    check(joinButton.onPressed).isNull();
    expect(find.bySemanticsLabel('Join, Loading'), findsOneWidget);
  });

  testWidgets(
    'teacher join button stays visible with loading while preparing',
    (
      tester,
    ) async {
      final bloc = JoinLoadingHoldBloc(
        seed: _inAppJoinSeed().copyWith(viewerRole: ActorRole.teacher),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      await tester.tap(find.text('Join'));
      await tester.pump();

      final joinButton = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (widget) => widget is TilawaButton && widget.text == 'Join',
        ),
      );
      check(joinButton.isLoading).isTrue();
      check(joinButton.onPressed).isNull();
      expect(find.bySemanticsLabel('Join, Loading'), findsOneWidget);
    },
  );

  testWidgets('open meeting again shows after external join opened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bloc = RecordingSessionDetailBloc(
      seed: _externalJoinSeed(
        meetingUrl: 'https://meet.google.com/room',
      ).copyWith(hasOpenedExternalMeeting: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<SessionDetailBloc>.value(
          value: bloc,
          child: const SessionDetailScreen(bookingId: 'session_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open meeting again'), findsOneWidget);
  });

  testWidgets(
    'mock in-app join hides mute when call gateway is not wired',
    (tester) async {
      final bloc = JoinNavigationTestBloc(seed: _inAppJoinSeed());

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('call_shell_end')), findsOneWidget);
      expect(find.bySemanticsLabel('Mute microphone'), findsNothing);
    },
  );

  testWidgets('invokes onSessionJoined with ids after a successful join', (
    tester,
  ) async {
    String? joinedBookingId;
    String? joinedSessionId;
    final bloc = JoinNavigationTestBloc(seed: _inAppJoinSeed());

    await _pumpSessionDetailScreen(
      tester,
      bloc: bloc,
      analytics: QuranSessionsAnalyticsCallbacks(
        onSessionJoined: ({bookingId, sessionId}) {
          joinedBookingId = bookingId;
          joinedSessionId = sessionId;
        },
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joinedBookingId, 'session_1');
    expect(joinedSessionId, 'session_1');
  });

  testWidgets('invokes onReviewSubmitted only after a successful submission', (
    tester,
  ) async {
    var reviewCount = 0;
    String? reviewBookingId;
    final bloc = ReviewEmitBloc(
      seed: SessionDetailSuccess(
        aggregate: makeAggregate(
          status: SessionLifecycleStatus.confirmed,
        ).copyWith(sessionId: 'session_1'),
        timeline: const [],
        viewerRole: ActorRole.student,
      ),
    );

    await _pumpSessionDetailScreen(
      tester,
      bloc: bloc,
      analytics: QuranSessionsAnalyticsCallbacks(
        onReviewSubmitted: ({bookingId, sessionId, rating}) {
          reviewCount++;
          reviewBookingId = bookingId;
        },
      ),
    );

    expect(reviewCount, 0);

    emitSessionDetailReviewSubmitted(bloc);
    await tester.pumpAndSettle();

    expect(reviewCount, 1);
    expect(reviewBookingId, 'session_1');
  });

  testWidgets(
    'counterparty sees pending reschedule banner and accept dispatches',
    (tester) async {
      final recorder = SessionDetailEventRecorder();
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rescheduled,
          ),
          timeline: const [],
          pendingRescheduleRequest: PendingRescheduleRequest(
            requestId: 'req_1',
            bookingId: 'booking_1',
            requestedByUserId: 'student_1',
            requestedByRole: ActorRole.student,
            reason: 'Conflict with work.',
            newStartsAt: DateTime.utc(2026, 7, 2, 14),
            status: 'pending',
          ),
          canRespondToReschedule: true,
        ),
        onRecord: recorder.record,
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Reschedule request'), findsOneWidget);
      expect(find.text('Accept new time'), findsOneWidget);

      await tester.tap(find.text('Accept new time'));
      await tester.pump();

      final respondEvents = recorder.events
          .whereType<SessionDetailRescheduleRespondSubmitted>()
          .toList();
      expect(respondEvents, hasLength(1));
      expect(respondEvents.single.accept, isTrue);
    },
  );

  testWidgets(
    'requester sees awaiting copy without respond actions on detail',
    (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rescheduled,
          ),
          timeline: const [],
          pendingRescheduleRequest: PendingRescheduleRequest(
            requestId: 'req_1',
            bookingId: 'booking_1',
            requestedByUserId: 'student_1',
            requestedByRole: ActorRole.student,
            reason: 'Need tomorrow afternoon.',
            newStartsAt: DateTime.utc(2026, 7, 2, 14),
            status: 'pending',
          ),
          isAwaitingRescheduleCounterparty: true,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(
        find.text(
          'Waiting for the other participant to confirm your new time.',
        ),
        findsOneWidget,
      );
      expect(find.text('Accept new time'), findsNothing);
      expect(find.text('Keep current time'), findsNothing);
    },
  );

  testWidgets('agora in-app join wires mute callback to call shell', (
    tester,
  ) async {
    final recordingGateway = _RecordingCallControlGateway();
    final bloc = JoinNavigationTestBloc(
      seed: _inAppJoinSeed(callProviderKind: SessionCallProviderKind.agora),
    );

    await _pumpSessionDetailScreen(
      tester,
      bloc: bloc,
      createCallControlGateway: (_) => recordingGateway,
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Mute microphone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('call_shell_mute')));
    await tester.pumpAndSettle();

    check(recordingGateway.microphoneEnabledCalls).deepEquals([false]);
    expect(find.bySemanticsLabel('Unmute microphone'), findsOneWidget);
  });

  group('join state banner', () {
    testWidgets('shows not started copy before join window', (tester) async {
      final startsAt = DateTime.now().toUtc().add(const Duration(days: 3));
      final aggregate = makeAggregate(
        status: SessionLifecycleStatus.confirmed,
        startsAt: startsAt,
      ).copyWith(sessionId: 'session_1');

      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: aggregate,
          timeline: const [],
          viewerRole: ActorRole.student,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(
        find.text('Join opens 15 minutes before your session starts.'),
        findsOneWidget,
      );
      expect(find.text('Join'), findsNothing);
    });
  });

  group('session detail cancel', () {
    testWidgets('cancel action dispatches when policy allows', (tester) async {
      final aggregate = makeAggregate(
        status: SessionLifecycleStatus.confirmed,
        startsAt: DateTime.now().toUtc().add(const Duration(days: 3)),
      ).copyWith(sessionId: 'session_1');

      final recorder = SessionDetailEventRecorder();
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: aggregate,
          timeline: const [],
          viewerRole: ActorRole.student,
        ),
        onRecord: recorder.record,
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Cancel session'), findsOneWidget);

      await tester.tap(find.text('Cancel session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Schedule conflict');
      await tester.tap(find.text('Cancel session').last);
      await tester.pumpAndSettle();

      expect(
        recorder.events.whereType<SessionDetailCancelSubmitted>(),
        hasLength(1),
      );
    });

    testWidgets(
      'tutor cancel shows dialog and dispatches without reason sheet',
      (
        tester,
      ) async {
        final aggregate = makeAggregate(
          status: SessionLifecycleStatus.scheduled,
          startsAt: DateTime.now().toUtc().add(const Duration(days: 3)),
        ).copyWith(sessionId: 'session_1');

        final recorder = SessionDetailEventRecorder();
        final bloc = RecordingSessionDetailBloc(
          seed: SessionDetailSuccess(
            aggregate: aggregate,
            timeline: const [],
            viewerRole: ActorRole.teacher,
          ),
          onRecord: recorder.record,
        );

        await _pumpSessionDetailScreen(tester, bloc: bloc);

        expect(find.text('Cancel session'), findsOneWidget);

        await tester.tap(find.text('Cancel session'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('The student will be notified'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);

        await tester.tap(find.text('Cancel session').last);
        await tester.pumpAndSettle();

        final events = recorder.events
            .whereType<SessionDetailCancelSubmitted>()
            .toList();
        check(events.length).equals(1);
        check(events.single.reason).equals(tutorCancelSessionReason);
      },
    );

    testWidgets('tutor cancel success returns refresh signal on back', (
      tester,
    ) async {
      bool? detailPopResult;
      final aggregate = makeAggregate(
        status: SessionLifecycleStatus.scheduled,
        startsAt: DateTime.now().toUtc().add(const Duration(days: 3)),
      ).copyWith(sessionId: 'session_1');

      final bloc = TutorCancelEmitSuccessBloc(
        seed: SessionDetailSuccess(
          aggregate: aggregate,
          timeline: const [],
          viewerRole: ActorRole.teacher,
        ),
      );

      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          builder: (context, child) => TilawaFeedbackHost(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TilawaButton(
                  text: 'Open detail',
                  onPressed: () async {
                    detailPopResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => BlocProvider<SessionDetailBloc>.value(
                          value: bloc,
                          child: const SessionDetailScreen(
                            bookingId: 'booking_1',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open detail'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel session').last);
      await tester.pumpAndSettle();

      expect(find.text('Cancel session'), findsNothing);
      expect(find.text('Join session'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      check(detailPopResult).equals(true);
    });

    testWidgets('tutor cancel hidden for pending approval', (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.pendingTutorApproval,
          ),
          timeline: const [],
          viewerRole: ActorRole.teacher,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Cancel session'), findsNothing);
    });

    testWidgets('tutor cancel hidden for rejected session', (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rejectedByTutor,
          ),
          timeline: const [],
          viewerRole: ActorRole.teacher,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Cancel session'), findsNothing);
    });

    testWidgets('student sees rejected copy without reason and no join', (
      tester,
    ) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rejectedByTutor,
            startsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
          ),
          timeline: const [],
          viewerRole: ActorRole.student,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Tutor declined this session'), findsOneWidget);
      expect(find.text('You can choose another time'), findsOneWidget);
      expect(find.text('Join session'), findsNothing);
    });

    testWidgets('student sees rejection reason when provided', (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rejectedByTutor,
            startsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
            rejectionReason: 'Schedule conflict',
          ),
          timeline: const [],
          viewerRole: ActorRole.student,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Tutor declined this session'), findsOneWidget);
      expect(find.text('Schedule conflict'), findsOneWidget);
      expect(find.text('Join session'), findsNothing);
    });

    testWidgets('student sees tutor-cancelled copy and no join', (
      tester,
    ) async {
      final aggregate = makeAggregate(
        status: SessionLifecycleStatus.cancelledByTeacher,
        startsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      ).copyWith(sessionId: 'session_1');

      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: aggregate,
          timeline: const [],
          viewerRole: ActorRole.student,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(
        find.text('Your tutor cancelled this session'),
        findsOneWidget,
      );
      expect(find.text('You can choose another time'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
      expect(find.text('Cancel session'), findsNothing);
    });
  });

  group('locked-at-booking footnote', () {
    testWidgets('shows for confirmed session with call context', (
      tester,
    ) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.confirmed,
          ),
          timeline: const [],
          callType: SessionCallType.voiceCall,
          callProviderKind: SessionCallProviderKind.agora,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(
        find.textContaining('Call type (Voice) and provider (In-app (Agora))'),
        findsOneWidget,
      );
      expect(
        find.textContaining('were set when you booked'),
        findsOneWidget,
      );
    });

    testWidgets('hidden when lifecycle is not booked', (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rescheduled,
          ),
          timeline: const [],
          callType: SessionCallType.voiceCall,
          callProviderKind: SessionCallProviderKind.agora,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.textContaining('were set when you booked'), findsNothing);
    });
  });

  group('sub-fetch failure banners', () {
    testWidgets('timeline load failure shows retry banner not empty copy', (
      tester,
    ) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.confirmed,
          ),
          timeline: const [],
          timelineLoadFailed: true,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(
        find.text(
          'Could not load the activity timeline. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No activity recorded yet.'), findsNothing);
    });

    testWidgets('pending reschedule load failure shows retry banner', (
      tester,
    ) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.rescheduled,
          ),
          timeline: const [],
          pendingRescheduleLoadFailed: true,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(
        find.text(
          'Could not load the pending reschedule request. Try again in a moment.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry on timeline banner dispatches reload', (tester) async {
      final recorder = SessionDetailEventRecorder();
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.confirmed,
          ),
          timeline: const [],
          timelineLoadFailed: true,
        ),
        onRecord: recorder.record,
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);
      recorder.clear();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(
        recorder.events.whereType<SessionDetailLoadRequested>(),
        hasLength(1),
      );
      expect(
        recorder.events.whereType<SessionDetailLoadRequested>().single,
        const SessionDetailLoadRequested(bookingId: 'session_1'),
      );
    });
  });

  group('revision practice CTA', () {
    testWidgets('shows and invokes host callback when surah context exists', (
      tester,
    ) async {
      int? tappedSurah;
      int? tappedAyah;

      final aggregate = makeAggregate(
        status: SessionLifecycleStatus.confirmed,
      ).copyWith(revisionSurahNumber: 18, revisionAyahNumber: 5);

      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: aggregate,
          timeline: const [],
        ),
      );

      await _pumpSessionDetailScreen(
        tester,
        bloc: bloc,
        onPracticeRevisionRequested:
            ({
              required surahNumber,
              ayahNumber,
            }) {
              tappedSurah = surahNumber;
              tappedAyah = ayahNumber;
            },
      );

      expect(find.text('Practice in Quran reader'), findsOneWidget);

      await tester.tap(find.text('Practice in Quran reader'));
      await tester.pump();

      check(tappedSurah).equals(18);
      check(tappedAyah).equals(5);
    });

    testWidgets('hidden without surah context', (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(status: SessionLifecycleStatus.confirmed),
          timeline: const [],
        ),
      );

      await _pumpSessionDetailScreen(
        tester,
        bloc: bloc,
        onPracticeRevisionRequested: ({required surahNumber, ayahNumber}) {},
      );

      expect(find.text('Practice in Quran reader'), findsNothing);
    });
  });

  group('cancelled session detail', () {
    testWidgets(
      'teacher-cancelled session hides join and shows friendly status',
      (tester) async {
        final event = SessionAuditEvent(
          sessionId: 'session_1',
          actorId: 'teacher_1',
          actorRole: ActorRole.teacher,
          action: SessionAction.confirmBooking,
          source: ActionSource.mobileApp,
          previousStatus: SessionLifecycleStatus.scheduled,
          newStatus: SessionLifecycleStatus.cancelledByTeacher,
          createdAt: DateTime.utc(2026, 6, 27),
          reason: 'tutor_cancelled',
        );

        final bloc = RecordingSessionDetailBloc(
          seed: SessionDetailSuccess(
            aggregate: makeAggregate(
              status: SessionLifecycleStatus.cancelledByTeacher,
            ),
            timeline: [event],
            viewerRole: ActorRole.teacher,
          ),
        );

        await _pumpSessionDetailScreen(tester, bloc: bloc);

        expect(find.text('Join session'), findsNothing);
        expect(find.text('Cancel session'), findsNothing);
        expect(find.textContaining('tutor_cancelled'), findsNothing);
        expect(find.text('You cancelled this session'), findsWidgets);
        expect(find.text('Session cancelled by tutor'), findsOneWidget);
      },
    );

    testWidgets('hides report and dispute actions for launch rollout', (
      tester,
    ) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.cancelledByTeacher,
          ),
          timeline: const [],
          viewerRole: ActorRole.student,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Report a concern'), findsNothing);
      expect(find.text('Open a dispute'), findsNothing);
      expect(
        find.textContaining('review this cancellation'),
        findsNothing,
      );
    });

    testWidgets('Arabic RTL cancelled detail has no overflow', (tester) async {
      final bloc = RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.cancelledByTeacher,
          ),
          timeline: const [],
          viewerRole: ActorRole.teacher,
        ),
      );

      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            ...QuranSessionsLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          builder: (context, child) => TilawaFeedbackHost(child: child!),
          home: BlocProvider<SessionDetailBloc>.value(
            value: bloc,
            child: const SessionDetailScreen(bookingId: 'session_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('tutor_cancelled'), findsNothing);
      expect(find.textContaining('ألغيت'), findsWidgets);
    });
  });
}

class _RecordingCallControlGateway implements SessionCallControlGateway {
  final List<bool> microphoneEnabledCalls = [];

  @override
  Future<void> leave() async {}

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {}

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {
    microphoneEnabledCalls.add(enabled);
  }

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {}

  @override
  Future<void> switchCamera() async {}
}
