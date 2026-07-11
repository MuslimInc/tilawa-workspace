import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_reschedule_request_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

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
  late FakeRescheduleRequestRepository rescheduleRequests;

  SessionDetailBloc buildBloc({
    GetSessionDetailUseCase? getSessionDetail,
    InvalidateQuranSessionCacheUseCase? invalidateCache,
    JoinSessionUseCase? joinSession,
    ReportSessionConcernUseCase? reportConcern,
    OpenSessionDisputeUseCase? openDispute,
    GetPendingRescheduleRequestUseCase? getPendingReschedule,
    RespondToRescheduleRequestUseCase? respondToReschedule,
    CancelSessionViaServerUseCase? cancelSession,
    AuthSessionProvider? authSession,
  }) {
    return SessionDetailBloc(
      getSessionAggregate: GetSessionAggregateUseCase(aggregateRepository),
      getTimeline: GetSessionTimelineUseCase(auditRepository),
      getSessionDetail: getSessionDetail,
      invalidateCache: invalidateCache,
      sessionRepository: sessionRepository,
      joinSession: joinSession,
      reportConcern: reportConcern,
      openDispute: openDispute,
      getPendingReschedule: getPendingReschedule,
      respondToReschedule: respondToReschedule,
      cancelSession: cancelSession,
      authSession: authSession,
      resolveActorRole: authSession == null
          ? null
          : ResolveSessionActorRoleUseCase(
              authSession: authSession,
              teacherProfileRepository: teacherProfiles,
            ),
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
    rescheduleRequests = FakeRescheduleRequestRepository();
  });

  blocTest<SessionDetailBloc, SessionDetailState>(
    'loads session call context through cache across repeated load requests',
    build: () => buildBloc(
      getSessionDetail: GetSessionDetailUseCase(
        sessionRepository: sessionRepository,
        cacheStore: MemoryCacheStore(),
      ),
    ),
    act: (bloc) async {
      bloc.add(const SessionDetailLoadRequested(bookingId: 'booking_1'));
      await bloc.stream.firstWhere((state) => state is SessionDetailSuccess);
      bloc.add(const SessionDetailLoadRequested(bookingId: 'booking_1'));
    },
    wait: const Duration(milliseconds: 10),
    verify: (_) {
      check(sessionRepository.getSessionByIdCallCount).equals(1);
    },
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'unauthorized timeline read succeeds with empty timeline not load failure',
    build: () => SessionDetailBloc(
      getSessionAggregate: GetSessionAggregateUseCase(aggregateRepository),
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
          .having((s) => s.timeline, 'timeline', isEmpty)
          .having(
            (s) => s.timelineLoadFailed,
            'timelineLoadFailed',
            isFalse,
          ),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'server timeline failure surfaces timelineLoadFailed on success state',
    build: () => SessionDetailBloc(
      getSessionAggregate: GetSessionAggregateUseCase(aggregateRepository),
      getTimeline: GetSessionTimelineUseCase(
        auditRepository..failWith = const ServerFailure(statusCode: 500),
      ),
    ),
    act: (bloc) => bloc.add(
      const SessionDetailLoadRequested(bookingId: 'booking_1'),
    ),
    expect: () => [
      const SessionDetailLoading(),
      isA<SessionDetailSuccess>()
          .having((s) => s.timeline, 'timeline', isEmpty)
          .having(
            (s) => s.timelineLoadFailed,
            'timelineLoadFailed',
            isTrue,
          ),
    ],
  );

  blocTest<SessionDetailBloc, SessionDetailState>(
    'requests timeline by booking id and linked session doc id',
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
        getSessionAggregate: GetSessionAggregateUseCase(aggregateRepository),
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
        getSessionAggregate: GetSessionAggregateUseCase(aggregateRepository),
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
      build: () {
        // Join window (Q-VC-03) opens 15m before start.
        sessionRepository.sessions = [
          makeSession(
            id: 'session_1',
            studentId: 'student_1',
            startsAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
          ),
        ];
        return buildBloc(joinSession: buildJoinUseCase(uid: 'student_1'));
      },
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

    blocTest<SessionDetailBloc, SessionDetailState>(
      'server pending reschedule failure surfaces pendingRescheduleLoadFailed',
      build: () => buildBloc(
        getPendingReschedule: GetPendingRescheduleRequestUseCase(
          repository: rescheduleRequests
            ..failWith = const ServerFailure(statusCode: 500),
        ),
      ),
      setUp: () {
        aggregateRepository.store['booking_1'] = makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.rescheduled,
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailLoadRequested(bookingId: 'booking_1'),
      ),
      expect: () => [
        const SessionDetailLoading(),
        isA<SessionDetailSuccess>()
            .having(
              (s) => s.pendingRescheduleLoadFailed,
              'pendingRescheduleLoadFailed',
              isTrue,
            )
            .having(
              (s) => s.pendingRescheduleRequest,
              'pendingRescheduleRequest',
              isNull,
            ),
      ],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'unauthorized pending reschedule read does not set load failure flag',
      build: () => buildBloc(
        getPendingReschedule: GetPendingRescheduleRequestUseCase(
          repository: rescheduleRequests
            ..failWith = const UnauthorizedFailure(),
        ),
      ),
      setUp: () {
        aggregateRepository.store['booking_1'] = makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.rescheduled,
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailLoadRequested(bookingId: 'booking_1'),
      ),
      expect: () => [
        const SessionDetailLoading(),
        isA<SessionDetailSuccess>()
            .having(
              (s) => s.pendingRescheduleLoadFailed,
              'pendingRescheduleLoadFailed',
              isFalse,
            )
            .having(
              (s) => s.pendingRescheduleRequest,
              'pendingRescheduleRequest',
              isNull,
            ),
      ],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'loads pending reschedule for counterparty when lifecycle is rescheduled',
      build: () => buildBloc(
        getPendingReschedule: GetPendingRescheduleRequestUseCase(
          repository: rescheduleRequests,
        ),
        authSession: _FakeAuthSession('teacher_user'),
      ),
      setUp: () {
        aggregateRepository.store['booking_1'] = makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.rescheduled,
        );
        rescheduleRequests.pendingByBooking['booking_1'] =
            PendingRescheduleRequest(
              requestId: 'req_1',
              bookingId: 'booking_1',
              requestedByUserId: 'student_1',
              requestedByRole: ActorRole.student,
              reason: 'Need a later time tomorrow.',
              newStartsAt: DateTime.utc(2026, 7, 2, 14),
              status: 'pending',
            );
        teacherProfiles.seed(
          makeTeacherProfile(id: 'teacher_1', userId: 'teacher_user'),
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailLoadRequested(bookingId: 'booking_1'),
      ),
      expect: () => [
        const SessionDetailLoading(),
        isA<SessionDetailSuccess>()
            .having((s) => s.canRespondToReschedule, 'canRespond', isTrue)
            .having(
              (s) => s.isAwaitingRescheduleCounterparty,
              'isAwaiting',
              isFalse,
            )
            .having(
              (s) => s.pendingRescheduleRequest?.requestId,
              'requestId',
              'req_1',
            ),
      ],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'accepting reschedule calls confirmSessionReschedule and updates aggregate',
      build: () => buildBloc(
        respondToReschedule: RespondToRescheduleRequestUseCase(
          mutationGateway: mutationGateway,
        ),
        authSession: _FakeAuthSession('teacher_user'),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
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
      setUp: () {
        teacherProfiles.seed(
          makeTeacherProfile(id: 'teacher_1', userId: 'teacher_user'),
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailRescheduleRespondSubmitted(accept: true),
      ),
      expect: () => [
        isA<SessionDetailSuccess>().having(
          (s) => s.rescheduleRespondInProgress,
          'inProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having(
              (s) => s.aggregate.lifecycleStatus,
              'lifecycleStatus',
              SessionLifecycleStatus.scheduled,
            )
            .having(
              (s) => s.rescheduleRespondAccepted,
              'accepted',
              isTrue,
            )
            .having(
              (s) => s.pendingRescheduleRequest,
              'pending cleared',
              isNull,
            ),
      ],
      verify: (_) {
        check(
          mutationGateway.calls,
        ).contains('confirmReschedule:req_1:true');
      },
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'rejecting reschedule calls confirmSessionReschedule with accept false',
      build: () => buildBloc(
        respondToReschedule: RespondToRescheduleRequestUseCase(
          mutationGateway: mutationGateway,
        ),
        authSession: _FakeAuthSession('teacher_user'),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
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
      setUp: () {
        teacherProfiles.seed(
          makeTeacherProfile(id: 'teacher_1', userId: 'teacher_user'),
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailRescheduleRespondSubmitted(accept: false),
      ),
      expect: () => [
        isA<SessionDetailSuccess>().having(
          (s) => s.rescheduleRespondInProgress,
          'inProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having(
              (s) => s.aggregate.lifecycleStatus,
              'lifecycleStatus',
              SessionLifecycleStatus.scheduled,
            )
            .having(
              (s) => s.rescheduleRespondAccepted,
              'accepted',
              isFalse,
            )
            .having(
              (s) => s.pendingRescheduleRequest,
              'pending cleared',
              isNull,
            ),
      ],
      verify: (_) {
        check(
          mutationGateway.calls,
        ).contains('confirmReschedule:req_1:false');
      },
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'reschedule respond failure surfaces rescheduleRespondFailure',
      build: () {
        mutationGateway.failConfirmRescheduleWith = const ServerFailure(
          statusCode: 500,
        );
        return buildBloc(
          respondToReschedule: RespondToRescheduleRequestUseCase(
            mutationGateway: mutationGateway,
          ),
          authSession: _FakeAuthSession('teacher_user'),
        );
      },
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
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
      setUp: () {
        teacherProfiles.seed(
          makeTeacherProfile(id: 'teacher_1', userId: 'teacher_user'),
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailRescheduleRespondSubmitted(accept: true),
      ),
      expect: () => [
        isA<SessionDetailSuccess>().having(
          (s) => s.rescheduleRespondInProgress,
          'inProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having(
              (s) => s.rescheduleRespondFailure,
              'failure',
              isA<ServerFailure>(),
            )
            .having(
              (s) => s.rescheduleRespondInProgress,
              'inProgress cleared',
              isFalse,
            )
            .having(
              (s) => s.pendingRescheduleRequest?.requestId,
              'pending kept',
              'req_1',
            ),
      ],
    );
  });

  group('session cancel', () {
    blocTest<SessionDetailBloc, SessionDetailState>(
      'load resolves teacher viewer role for owning tutor',
      build: () => buildBloc(authSession: _FakeAuthSession('teacher_user')),
      setUp: () {
        teacherProfiles.seed(
          makeTeacherProfile(id: 'teacher_1', userId: 'teacher_user'),
        );
      },
      act: (bloc) => bloc.add(
        const SessionDetailLoadRequested(bookingId: 'booking_1'),
      ),
      expect: () => [
        const SessionDetailLoading(),
        isA<SessionDetailSuccess>().having(
          (s) => s.viewerRole,
          'viewerRole',
          ActorRole.teacher,
        ),
      ],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'teacher cancel transitions aggregate to cancelledByTeacher',
      build: () => buildBloc(
        cancelSession: buildCancelSessionViaServerUseCase(
          repository: aggregateRepository,
        ),
        authSession: _FakeAuthSession('teacher_user'),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.confirmed,
        ),
        timeline: const [],
        viewerRole: ActorRole.teacher,
      ),
      act: (bloc) => bloc.add(
        const SessionDetailCancelSubmitted(reason: 'tutor_cancelled'),
      ),
      expect: () => [
        isA<SessionDetailSuccess>().having(
          (s) => s.cancellationInProgress,
          'inProgress',
          isTrue,
        ),
        isA<SessionDetailSuccess>()
            .having(
              (s) => s.aggregate.lifecycleStatus,
              'status',
              SessionLifecycleStatus.cancelledByTeacher,
            )
            .having(
              (s) => s.cancellationSucceeded,
              'succeeded',
              isTrue,
            ),
      ],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'teacher cancel ignored for pending tutor approval',
      build: () => buildBloc(
        cancelSession: buildCancelSessionViaServerUseCase(
          repository: aggregateRepository,
        ),
        authSession: _FakeAuthSession('teacher_user'),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.pendingTutorApproval,
        ),
        timeline: const [],
        viewerRole: ActorRole.teacher,
      ),
      act: (bloc) => bloc.add(
        const SessionDetailCancelSubmitted(reason: 'tutor_cancelled'),
      ),
      expect: () => <SessionDetailState>[],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'teacher cancel ignored for non-owning viewer role',
      build: () => buildBloc(
        cancelSession: buildCancelSessionViaServerUseCase(
          repository: aggregateRepository,
        ),
        authSession: _FakeAuthSession('other_teacher'),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.confirmed,
        ),
        timeline: const [],
        viewerRole: null,
      ),
      act: (bloc) => bloc.add(
        const SessionDetailCancelSubmitted(reason: 'tutor_cancelled'),
      ),
      expect: () => <SessionDetailState>[],
    );

    blocTest<SessionDetailBloc, SessionDetailState>(
      'second teacher cancel is ignored when already cancelled',
      build: () => buildBloc(
        cancelSession: buildCancelSessionViaServerUseCase(
          repository: aggregateRepository,
        ),
        authSession: _FakeAuthSession('teacher_user'),
      ),
      seed: () => SessionDetailSuccess(
        aggregate: makeAggregate(
          id: 'booking_1',
          status: SessionLifecycleStatus.cancelledByTeacher,
        ),
        timeline: const [],
        viewerRole: ActorRole.teacher,
      ),
      act: (bloc) => bloc.add(
        const SessionDetailCancelSubmitted(reason: 'tutor_cancelled'),
      ),
      expect: () => <SessionDetailState>[],
    );
  });
}
