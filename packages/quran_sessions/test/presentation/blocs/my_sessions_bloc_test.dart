import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';
import '../../helpers/fixtures.dart' show makeBooking, makeSession;

void main() {
  late FakeSessionRepository sessionRepo;
  late FakeBookingRepository bookingRepo;
  late MySessionsBloc bloc;

  late FakeSessionAggregateRepository aggregateRepo;
  late MockSessionCallProvider mockProvider;
  late JoinSessionUseCase joinSessionUseCase;
  CallJoinRequest? lastJoin;

  setUp(() {
    sessionRepo = FakeSessionRepository();
    bookingRepo = FakeBookingRepository();
    aggregateRepo = FakeSessionAggregateRepository();
    lastJoin = null;
    mockProvider = MockSessionCallProvider(onJoin: (r) => lastJoin = r);
    joinSessionUseCase = JoinSessionUseCase(
      sessionRepository: sessionRepo,
      callProvider: mockProvider,
      authSession: _FakeAuthSession('student_1'),
      teacherProfileRepository: FakeTeacherProfileRepository(),
    );
    bloc = MySessionsBloc(
      getStudentSessions: GetStudentSessionsUseCase(sessionRepo),
      cancelSession: buildCancelSessionViaServerUseCase(
        repository: aggregateRepo,
      ),
      submitReview: SubmitReviewUseCase(bookingRepo),
      joinSession: joinSessionUseCase,
      studentId: 'student_1',
    );
  });

  tearDown(() => bloc.close());

  group('MySessionsBloc', () {
    blocTest<MySessionsBloc, MySessionsState>(
      'emits [Loading, Empty] when student has no sessions',
      build: () => bloc,
      act: (b) => b.add(
        const MySessionsLoadRequested(studentId: 'student_1'),
      ),
      expect: () => [
        isA<MySessionsLoading>(),
        isA<MySessionsEmpty>(),
      ],
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'emits [Loading, Success] and partitions upcoming vs past',
      build: () {
        sessionRepo.sessions = [
          makeSession(
            id: 'future',
            studentId: 'student_1',
            startsAt: DateTime.now().add(const Duration(days: 2)),
          ),
          makeSession(
            id: 'past',
            studentId: 'student_1',
            status: QuranSessionStatus.completed,
            startsAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        return bloc;
      },
      act: (b) => b.add(const MySessionsLoadRequested(studentId: 'student_1')),
      expect: () => [
        isA<MySessionsLoading>(),
        isA<MySessionsSuccess>(),
      ],
      verify: (b) {
        final state = b.state as MySessionsSuccess;
        check(state.upcoming).length.equals(1);
        check(state.past).length.equals(1);
        check(state.upcoming.first.id).equals('future');
      },
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'emits [Loading, Failure] on repository error',
      build: () {
        sessionRepo.failWith = const NetworkFailure();
        return bloc;
      },
      act: (b) => b.add(const MySessionsLoadRequested(studentId: 'student_1')),
      expect: () => [
        isA<MySessionsLoading>(),
        isA<MySessionsFailure>(),
      ],
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'SessionCancelled removes session from upcoming list',
      build: () {
        aggregateRepo.store['booking_1'] = makeAggregate(
          id: 'booking_1',
          startsAt: DateTime.now().add(const Duration(days: 2)),
        );
        return bloc;
      },
      seed: () => MySessionsSuccess(
        upcoming: [makeSession(id: 's1', studentId: 'student_1')],
        past: const [],
      ),
      act: (b) => b.add(
        const SessionCancelled(bookingId: 'booking_1', reason: 'changed mind'),
      ),
      verify: (b) {
        final state = b.state as MySessionsSuccess;
        check(state.upcoming).isEmpty();
        check(state.cancellationInProgress).isNull();
      },
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'SessionJoinRequested invokes SessionCallProvider',
      build: () {
        sessionRepo.sessions = [
          makeSession(id: 'session_join', studentId: 'student_1'),
        ];
        return bloc;
      },
      seed: () => MySessionsSuccess(
        upcoming: [makeSession(id: 'session_join', studentId: 'student_1')],
        past: const [],
      ),
      act: (b) => b.add(const SessionJoinRequested(sessionId: 'session_join')),
      verify: (_) {
        check(lastJoin?.sessionId).equals('session_join');
      },
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'successful join sets joinCompletedSessionId and clears progress',
      build: () {
        sessionRepo.sessions = [
          makeSession(id: 'session_join', studentId: 'student_1'),
        ];
        return bloc;
      },
      seed: () => MySessionsSuccess(
        upcoming: [makeSession(id: 'session_join', studentId: 'student_1')],
        past: const [],
      ),
      act: (b) => b.add(const SessionJoinRequested(sessionId: 'session_join')),
      expect: () => [
        isA<MySessionsSuccess>().having(
          (s) => s.joinInProgress,
          'joinInProgress',
          'session_join',
        ),
        isA<MySessionsSuccess>()
            .having(
              (s) => s.joinCompletedSessionId,
              'joinCompletedSessionId',
              'session_join',
            )
            .having((s) => s.joinInProgress, 'joinInProgress', isNull),
      ],
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'failed join surfaces joinFailure without joinCompletedSessionId',
      build: () {
        sessionRepo.sessions = [
          makeSession(id: 'session_join', studentId: 'student_1'),
        ];
        mockProvider = MockSessionCallProvider(
          onJoin: (_) =>
              throw const RtcCallJoinFailure(reasonCode: 'join_failed'),
        );
        joinSessionUseCase = JoinSessionUseCase(
          sessionRepository: sessionRepo,
          callProvider: mockProvider,
          authSession: _FakeAuthSession('student_1'),
          teacherProfileRepository: FakeTeacherProfileRepository(),
        );
        bloc = MySessionsBloc(
          getStudentSessions: GetStudentSessionsUseCase(sessionRepo),
          cancelSession: buildCancelSessionViaServerUseCase(
            repository: aggregateRepo,
          ),
          submitReview: SubmitReviewUseCase(bookingRepo),
          joinSession: joinSessionUseCase,
          studentId: 'student_1',
        );
        return bloc;
      },
      seed: () => MySessionsSuccess(
        upcoming: [makeSession(id: 'session_join', studentId: 'student_1')],
        past: const [],
      ),
      act: (b) => b.add(const SessionJoinRequested(sessionId: 'session_join')),
      verify: (b) {
        final state = b.state as MySessionsSuccess;
        check(state.joinFailure).isA<RtcCallJoinFailure>();
        check(state.joinCompletedSessionId).isNull();
        check(state.joinInProgress).isNull();
      },
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'MySessionsJoinCompletedAcknowledged clears joinCompletedSessionId',
      build: () => bloc,
      seed: () => MySessionsSuccess(
        upcoming: const [],
        past: const [],
        joinCompletedSessionId: 'session_join',
      ),
      act: (b) => b.add(const MySessionsJoinCompletedAcknowledged()),
      verify: (b) {
        final state = b.state as MySessionsSuccess;
        check(state.joinCompletedSessionId).isNull();
      },
    );

    blocTest<MySessionsBloc, MySessionsState>(
      'ReviewSubmitted sets lastSubmittedReview',
      build: () => bloc,
      seed: () => MySessionsSuccess(
        upcoming: const [],
        past: [makeSession(id: 's1', studentId: 'student_1')],
      ),
      act: (b) => b.add(
        const ReviewSubmitted(sessionId: 's1', rating: 5, comment: 'Great!'),
      ),
      verify: (b) {
        final state = b.state as MySessionsSuccess;
        check(state.lastSubmittedReview).isNotNull();
        check(state.lastSubmittedReview!.rating).equals(5);
      },
    );
  });
}

class _FakeAuthSession implements AuthSessionProvider {
  _FakeAuthSession(this.userId);
  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
