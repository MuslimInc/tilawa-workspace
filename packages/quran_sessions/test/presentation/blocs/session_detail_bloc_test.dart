import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.uid);

  final String uid;

  @override
  String? get currentUserId => uid;

  @override
  Stream<String?> watchUserId() => Stream.value(uid);
}

void main() {
  late FakeSessionAggregateRepository aggregateRepository;
  late FakeAuditRepository auditRepository;
  late FakeSessionRepository sessionRepository;
  late FakeSessionMutationGateway mutationGateway;
  late FakeTeacherProfileRepository teacherProfiles;

  SessionDetailBloc buildBloc({
    JoinSessionUseCase? joinSession,
    ReportSessionConcernUseCase? reportConcern,
    OpenSessionDisputeUseCase? openDispute,
  }) {
    return SessionDetailBloc(
      aggregateRepository: aggregateRepository,
      getTimeline: GetSessionTimelineUseCase(auditRepository),
      sessionRepository: sessionRepository,
      joinSession: joinSession,
      reportConcern: reportConcern,
      openDispute: openDispute,
    );
  }

  JoinSessionUseCase buildJoinUseCase({required String uid}) {
    return JoinSessionUseCase(
      sessionRepository: sessionRepository,
      callProvider: RoutingSessionCallProvider(
        external: ExternalMeetingCallProvider(
          getMeetingUrl: (_) async => 'https://meet.example.com/room',
          urlLauncher: (_) async {},
        ),
        mock: MockSessionCallProvider(onJoin: (_) {}),
      ),
      authSession: _FakeAuthSession(uid),
      teacherProfileRepository: teacherProfiles,
    );
  }

  setUp(() {
    aggregateRepository = FakeSessionAggregateRepository()
      ..store['booking_1'] = makeAggregate(id: 'booking_1').copyWith(
        sessionId: 'session_1',
      );
    auditRepository = FakeAuditRepository();
    sessionRepository = FakeSessionRepository()
      ..sessions = [
        makeSession(
          id: 'session_1',
          studentId: 'student_1',
        ),
      ];
    mutationGateway = FakeSessionMutationGateway();
    teacherProfiles = FakeTeacherProfileRepository();
  });

  blocTest<SessionDetailBloc, SessionDetailState>(
    'loads session detail when timeline read is denied',
    build: () => SessionDetailBloc(
      aggregateRepository: aggregateRepository,
      getTimeline: GetSessionTimelineUseCase(
        auditRepository..failWith = const UnauthorizedFailure(),
      ),
    ),
    act: (bloc) => bloc.add(
      const SessionDetailLoadRequested(bookingId: 'booking_1'),
    ),
    expect: () => [
      const SessionDetailLoading(),
      isA<SessionDetailSuccess>()
          .having((s) => s.aggregate.id, 'aggregate id', 'booking_1')
          .having((s) => s.timeline, 'timeline', isEmpty),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'requests timeline by linked session id',
    build: () {
      auditRepository.events.add(
        SessionAuditEvent(
          sessionId: 'session_1',
          actorId: 'student_1',
          actorRole: ActorRole.student,
          action: SessionAction.createDraft,
          source: ActionSource.mobileApp,
          previousStatus: SessionLifecycleStatus.scheduled,
          newStatus: SessionLifecycleStatus.scheduled,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      return SessionDetailBloc(
        aggregateRepository: aggregateRepository,
        getTimeline: GetSessionTimelineUseCase(auditRepository),
      );
    },
    act: (bloc) => bloc.add(
      const SessionDetailLoadRequested(bookingId: 'booking_1'),
    ),
    expect: () => [
      const SessionDetailLoading(),
      isA<SessionDetailSuccess>().having(
        (s) => s.timeline.length,
        'timeline length',
        1,
      ),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'load copies callProviderKind from linked session',
    build: () {
      final start = DateTime.now().add(const Duration(days: 1));
      sessionRepository.sessions = [
        QuranSession(
          id: 'session_1',
          bookingId: 'booking_1',
          teacherId: 'teacher_1',
          studentId: 'student_1',
          startsAt: start,
          endsAt: start.add(const Duration(hours: 1)),
          callType: SessionCallType.voiceCall,
          status: QuranSessionStatus.scheduled,
          callProviderKind: SessionCallProviderKind.agora,
        ),
      ];
      return SessionDetailBloc(
        aggregateRepository: aggregateRepository,
        getTimeline: GetSessionTimelineUseCase(auditRepository),
        sessionRepository: sessionRepository,
      );
    },
    act: (bloc) => bloc.add(
      const SessionDetailLoadRequested(bookingId: 'booking_1'),
    ),
    expect: () => [
      const SessionDetailLoading(),
      isA<SessionDetailSuccess>()
          .having(
            (s) => s.callProviderKind,
            'callProviderKind',
            SessionCallProviderKind.agora,
          )
          .having(
            (s) => s.supportsInAppMicrophoneMute,
            'supportsInAppMicrophoneMute',
            isTrue,
          ),
    ],
  );

  group('join', () {
    blocTest<SessionDetailBloc, SessionDetailState>(
      'student join clears in-progress and marks external meeting opened',
      build: () => buildBloc(joinSession: buildJoinUseCase(uid: 'student_1')),
      act: (bloc) async {
        bloc.add(const SessionDetailLoadRequested(bookingId: 'booking_1'));
        await bloc.stream.firstWhere((s) => s is SessionDetailSuccess);
        bloc.add(const SessionDetailJoinRequested());
        await bloc.stream.firstWhere(
          (s) =>
              s is SessionDetailSuccess &&
              !s.joinInProgress &&
              s.hasOpenedExternalMeeting,
        );
      },
      expect: () => [
        const SessionDetailLoading(),
        isA<SessionDetailSuccess>(),
        isA<SessionDetailSuccess>().having(
          (s) => s.joinInProgress,
          'joinInProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having((s) => s.joinInProgress, 'joinInProgress', isFalse)
            .having(
              (s) => s.hasOpenedExternalMeeting,
              'hasOpenedExternalMeeting',
              isTrue,
            ),
      ],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'join failure surfaces joinFailure on success state',
      build: () {
        sessionRepository.sessions = [
          makeSession(
            id: 'session_1',
            studentId: 'other_student',
          ),
        ];
        return buildBloc(joinSession: buildJoinUseCase(uid: 'student_1'));
      },
      act: (bloc) async {
        bloc.add(const SessionDetailLoadRequested(bookingId: 'booking_1'));
        await bloc.stream.firstWhere((s) => s is SessionDetailSuccess);
        bloc.add(const SessionDetailJoinRequested());
        await bloc.stream.firstWhere(
          (s) => s is SessionDetailSuccess && s.joinFailure != null,
        );
      },
      expect: () => [
        const SessionDetailLoading(),
        isA<SessionDetailSuccess>(),
        isA<SessionDetailSuccess>().having(
          (s) => s.joinInProgress,
          'joinInProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having((s) => s.joinFailure, 'joinFailure', isNotNull)
            .having((s) => s.joinInProgress, 'joinInProgress', isFalse),
      ],
    );
  });

  group('report and dispute', () {
    blocTest<SessionDetailBloc, SessionDetailState>(
      'report submission sets reportSubmitted when gateway succeeds',
      build: () => buildBloc(
        reportConcern: ReportSessionConcernUseCase(
          gateway: mutationGateway,
        ),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(id: 'booking_1'),
        timeline: const [],
      ),
      act: (bloc) => bloc.add(
        const SessionDetailReportSubmitted(
          category: SessionReportCategory.other,
          description: 'Audio dropped repeatedly during the lesson.',
        ),
      ),
      expect: () => [
        isA<SessionDetailSuccess>().having(
          (s) => s.reportInProgress,
          'reportInProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having((s) => s.reportSubmitted, 'reportSubmitted', isTrue)
            .having((s) => s.reportInProgress, 'reportInProgress', isFalse),
      ],
      verify: (_) {
        check(mutationGateway.calls).contains('report:other');
      },
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'dispute submission moves aggregate to disputed lifecycle',
      build: () => buildBloc(
        openDispute: OpenSessionDisputeUseCase(gateway: mutationGateway),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(id: 'booking_1'),
        timeline: const [],
      ),
      act: (bloc) => bloc.add(
        const SessionDetailDisputeSubmitted(
          reason: 'Teacher did not attend the scheduled session.',
        ),
      ),
      expect: () => [
        isA<SessionDetailSuccess>().having(
          (s) => s.disputeInProgress,
          'disputeInProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having((s) => s.disputeSubmitted, 'disputeSubmitted', isTrue)
            .having(
              (s) => s.aggregate.lifecycleStatus,
              'lifecycleStatus',
              SessionLifecycleStatus.disputed,
            ),
      ],
      verify: (_) {
        check(mutationGateway.calls).contains('dispute:booking_1');
      },
    );
  });
}
