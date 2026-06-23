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

    expect(find.text('Join outside Tilawa?'), findsOneWidget);
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
}
