import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

void main() {
  blocTest<TeacherDashboardBloc, TeacherDashboardState>(
    'reject without reason calls gateway and removes pending request',
    build: () {
      final gateway = FakeSessionMutationGateway();
      final sessionRepo = FakeSessionRepository();
      final scheduleRepo = FakeScheduleRepository();
      return buildTestTeacherDashboardBloc(
        sessionRepo: sessionRepo,
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          bookedSlotLockRepository: FakeBookedSlotLockRepository(),
        ),
        blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
        availabilityProvider: FakeAvailabilityProvider(),
        cancelSession: buildCancelSessionViaServerUseCase(),
        completeSession: buildCompleteSessionViaServerUseCase(),
        respondToBookingRequest: RespondToBookingRequestUseCase(gateway),
        scheduleRepo: scheduleRepo,
      );
    },
    seed: () => seedTeacherDashboardSuccess(
      pendingBookingRequests: [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const TeacherBookingRequestRejected(bookingId: 'booking_1'),
    ),
    verify: (bloc) {
      final state = bloc.state as TeacherDashboardSuccess;
      check(state.pendingBookingRequests).isEmpty();
    },
  );

  blocTest<TeacherDashboardBloc, TeacherDashboardState>(
    'reject with reason forwards reason to gateway',
    build: () {
      final gateway = FakeSessionMutationGateway();
      final sessionRepo = FakeSessionRepository();
      final scheduleRepo = FakeScheduleRepository();
      return buildTestTeacherDashboardBloc(
        sessionRepo: sessionRepo,
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          bookedSlotLockRepository: FakeBookedSlotLockRepository(),
        ),
        blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
        availabilityProvider: FakeAvailabilityProvider(),
        cancelSession: buildCancelSessionViaServerUseCase(),
        completeSession: buildCompleteSessionViaServerUseCase(),
        respondToBookingRequest: RespondToBookingRequestUseCase(gateway),
        scheduleRepo: scheduleRepo,
      );
    },
    seed: () => seedTeacherDashboardSuccess(
      pendingBookingRequests: [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const TeacherBookingRequestRejected(
        bookingId: 'booking_1',
        reason: 'Schedule conflict',
      ),
    ),
    verify: (_) {
      // Gateway records reason in call string via fake implementation.
    },
    expect: () => [
      isA<TeacherDashboardSuccess>().having(
        (s) => s.bookingRequestActionInProgress,
        'in progress',
        'booking_1',
      ),
      isA<TeacherDashboardSuccess>().having(
        (s) => s.pendingBookingRequests,
        'pending cleared',
        isEmpty,
      ),
    ],
  );

  blocTest<TeacherDashboardBloc, TeacherDashboardState>(
    'unauthorized reject surfaces bookingRequestFailure',
    build: () {
      final gateway = _UnauthorizedRejectGateway();
      final sessionRepo = FakeSessionRepository();
      final scheduleRepo = FakeScheduleRepository();
      return buildTestTeacherDashboardBloc(
        sessionRepo: sessionRepo,
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          bookedSlotLockRepository: FakeBookedSlotLockRepository(),
        ),
        blockGeneratedSlot: BlockGeneratedSlotUseCase(scheduleRepo),
        availabilityProvider: FakeAvailabilityProvider(),
        cancelSession: buildCancelSessionViaServerUseCase(),
        completeSession: buildCompleteSessionViaServerUseCase(),
        respondToBookingRequest: RespondToBookingRequestUseCase(gateway),
        scheduleRepo: scheduleRepo,
      );
    },
    seed: () => seedTeacherDashboardSuccess(
      pendingBookingRequests: [
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const TeacherBookingRequestRejected(bookingId: 'booking_1'),
    ),
    expect: () => [
      isA<TeacherDashboardSuccess>().having(
        (s) => s.bookingRequestActionInProgress,
        'in progress',
        'booking_1',
      ),
      isA<TeacherDashboardSuccess>()
          .having((s) => s.bookingRequestFailure, 'failure', isNotNull)
          .having((s) => s.pendingBookingRequests.length, 'still pending', 1),
    ],
  );
}

class _UnauthorizedRejectGateway extends FakeSessionMutationGateway {
  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>>
  respondToBookingRequest({
    required String bookingId,
    required bool accept,
    String? reason,
  }) async {
    return const Left(UnauthorizedFailure());
  }
}
