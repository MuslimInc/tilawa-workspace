import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

class _RecordingSessionDetailBloc extends SessionDetailBloc {
  _RecordingSessionDetailBloc({
    required SessionDetailSuccess seed,
  }) : super(
         aggregateRepository: FakeSessionAggregateRepository(),
         getTimeline: GetSessionTimelineUseCase(FakeAuditRepository()),
       ) {
    emit(seed);
  }

  final recordedEvents = <SessionDetailEvent>[];

  @override
  void add(SessionDetailEvent event) {
    recordedEvents.add(event);
  }
}

class _JoinNavigationTestBloc extends SessionDetailBloc {
  _JoinNavigationTestBloc({required SessionDetailSuccess seed})
    : super(
        aggregateRepository: FakeSessionAggregateRepository(),
        getTimeline: GetSessionTimelineUseCase(FakeAuditRepository()),
      ) {
    emit(seed);
  }

  @override
  void add(SessionDetailEvent event) {
    if (event is SessionDetailLoadRequested) {
      return;
    }
    if (event is SessionDetailJoinRequested) {
      final current = state;
      if (current is! SessionDetailSuccess) {
        return;
      }
      emit(current.copyWith(joinInProgress: true));
      emit(current.copyWith(joinInProgress: false, clearJoinFailure: true));
      return;
    }
    super.add(event);
  }
}

Future<void> _pumpSessionDetailScreen(
  WidgetTester tester, {
  required SessionDetailBloc bloc,
  Future<void> Function(String sessionId)? onLeaveCall,
  Future<void> Function(String sessionId, {required bool muted})?
  onSetMicrophoneMuted,
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
      home: BlocProvider<SessionDetailBloc>.value(
        value: bloc,
        child: SessionDetailScreen(
          bookingId: 'session_1',
          onLeaveCall: onLeaveCall,
          onSetMicrophoneMuted: onSetMicrophoneMuted,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SessionDetailSuccess _inAppJoinSeed({
  SessionCallProviderKind callProviderKind = SessionCallProviderKind.mock,
}) {
  final aggregate = makeAggregate(
    status: SessionLifecycleStatus.confirmed,
  ).copyWith(sessionId: 'session_1');

  return SessionDetailSuccess(
    aggregate: aggregate,
    timeline: const [],
    callProviderKind: callProviderKind,
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

    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
    ).copyWith(sessionId: 'session_1');

    final bloc = _RecordingSessionDetailBloc(
      seed: SessionDetailSuccess(
        aggregate: aggregate,
        timeline: const [],
        externalMeetingJoinUrl: 'https://meet.google.com/room',
      ),
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

    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
    ).copyWith(sessionId: 'session_1');

    final bloc = _RecordingSessionDetailBloc(
      seed: SessionDetailSuccess(
        aggregate: aggregate,
        timeline: const [],
        externalMeetingJoinUrl: 'https://meet.google.com/room',
      ),
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
      bloc.recordedEvents.whereType<SessionDetailJoinRequested>(),
      isEmpty,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      bloc.recordedEvents.whereType<SessionDetailJoinRequested>(),
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

    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
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
          create: (_) => _RecordingSessionDetailBloc(
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

  testWidgets('open meeting again shows after external join opened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
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
          create: (_) => _RecordingSessionDetailBloc(
            seed: SessionDetailSuccess(
              aggregate: aggregate,
              timeline: const [],
              externalMeetingJoinUrl: 'https://meet.google.com/room',
              hasOpenedExternalMeeting: true,
            ),
          ),
          child: const SessionDetailScreen(bookingId: 'session_1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open meeting again'), findsOneWidget);
  });

  testWidgets(
    'mock in-app join hides mute even when nav wires mute callback',
    (tester) async {
      final bloc = _JoinNavigationTestBloc(seed: _inAppJoinSeed());

      await _pumpSessionDetailScreen(
        tester,
        bloc: bloc,
        onSetMicrophoneMuted: (_, {required muted}) async {},
      );

      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      expect(find.text('Leave call'), findsOneWidget);
      expect(find.text('Mute microphone'), findsNothing);
    },
  );

  testWidgets(
    'counterparty sees pending reschedule banner and accept dispatches',
    (tester) async {
      final bloc = _RecordingSessionDetailBloc(
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
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);

      expect(find.text('Reschedule request'), findsOneWidget);
      expect(find.text('Accept new time'), findsOneWidget);

      await tester.tap(find.text('Accept new time'));
      await tester.pump();

      final respondEvents = bloc.recordedEvents
          .whereType<SessionDetailRescheduleRespondSubmitted>()
          .toList();
      expect(respondEvents, hasLength(1));
      expect(respondEvents.single.accept, isTrue);
    },
  );

  testWidgets(
    'requester sees awaiting copy without respond actions on detail',
    (tester) async {
      final bloc = _RecordingSessionDetailBloc(
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
    final muteEvents = <String>[];
    final bloc = _JoinNavigationTestBloc(
      seed: _inAppJoinSeed(callProviderKind: SessionCallProviderKind.agora),
    );

    await _pumpSessionDetailScreen(
      tester,
      bloc: bloc,
      onSetMicrophoneMuted: (sessionId, {required bool muted}) async {
        muteEvents.add('$sessionId:${muted ? 'mute' : 'unmute'}');
      },
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('Mute microphone'), findsOneWidget);

    await tester.tap(find.text('Mute microphone'));
    await tester.pumpAndSettle();

    expect(muteEvents, ['session_1:mute']);
    expect(find.text('Unmute microphone'), findsOneWidget);
  });

  group('locked-at-booking footnote', () {
    testWidgets('shows for confirmed session with call context', (
      tester,
    ) async {
      final bloc = _RecordingSessionDetailBloc(
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
      final bloc = _RecordingSessionDetailBloc(
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
      final bloc = _RecordingSessionDetailBloc(
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
      final bloc = _RecordingSessionDetailBloc(
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
      final bloc = _RecordingSessionDetailBloc(
        seed: SessionDetailSuccess(
          aggregate: makeAggregate(
            status: SessionLifecycleStatus.confirmed,
          ),
          timeline: const [],
          timelineLoadFailed: true,
        ),
      );

      await _pumpSessionDetailScreen(tester, bloc: bloc);
      bloc.recordedEvents.clear();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(
        bloc.recordedEvents.whereType<SessionDetailLoadRequested>(),
        hasLength(1),
      );
      expect(
        bloc.recordedEvents.whereType<SessionDetailLoadRequested>().single,
        const SessionDetailLoadRequested(bookingId: 'session_1'),
      );
    });
  });
}
