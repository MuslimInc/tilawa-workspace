import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';

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

void main() {
  late FakeSessionRepository sessionRepo;
  late MockSessionCallProvider mockProvider;
  CallJoinRequest? lastJoin;

  setUp(() {
    sessionRepo = FakeSessionRepository();
    lastJoin = null;
    mockProvider = MockSessionCallProvider(
      onJoin: (request) => lastJoin = request,
    );
  });

  TeacherDashboardBloc buildBloc() {
    return buildTestTeacherDashboardBloc(
      sessionRepo: sessionRepo,
      getAvailability: SpyGetTeacherAvailabilityUseCase(
        scheduleRepository: FakeScheduleRepository(),
        bookedSlotLocks: FakeBookedSlotLockRepository(),
      ),
      blockGeneratedSlot: BlockGeneratedSlotUseCase(FakeScheduleRepository()),
      availabilityProvider: FakeAvailabilityProvider(),
      cancelSession: buildCancelSessionViaServerUseCase(),
      completeSession: buildCompleteSessionViaServerUseCase(),
      scheduleRepo: FakeScheduleRepository(),
      joinSession: buildJoinSessionUseCase(
        sessionRepository: sessionRepo,
        userId: 'teacher_1',
        callProvider: mockProvider,
        teacherProfileRepository: FakeTeacherProfileRepository(),
      ),
    );
  }

  blocTest<TeacherDashboardBloc, TeacherDashboardState>(
    'TeacherDashboardSessionJoinRequested invokes SessionCallProvider',
    build: () {
      sessionRepo.sessions = [_inAppUpcomingSession()];
      return buildBloc();
    },
    seed: () => seedTeacherDashboardSuccess(
      upcomingSessions: [_inAppUpcomingSession()],
    ),
    act: (bloc) => bloc.add(
      const TeacherDashboardSessionJoinRequested(sessionId: 'session_join'),
    ),
    verify: (_) {
      check(lastJoin?.sessionId).equals('session_join');
    },
  );

  blocTest<TeacherDashboardBloc, TeacherDashboardState>(
    'successful dashboard join sets joinCompletedSessionId',
    build: () {
      sessionRepo.sessions = [_inAppUpcomingSession()];
      return buildBloc();
    },
    seed: () => seedTeacherDashboardSuccess(
      upcomingSessions: [_inAppUpcomingSession()],
    ),
    act: (bloc) => bloc.add(
      const TeacherDashboardSessionJoinRequested(sessionId: 'session_join'),
    ),
    expect: () => [
      isA<TeacherDashboardSuccess>().having(
        (s) => s.joinInProgress,
        'joinInProgress',
        'session_join',
      ),
      isA<TeacherDashboardSuccess>()
          .having(
            (s) => s.joinCompletedSessionId,
            'joinCompletedSessionId',
            'session_join',
          )
          .having((s) => s.joinInProgress, 'joinInProgress', isNull),
    ],
  );
}
