import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_availability_provider.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';
import '../../helpers/lifecycle_test_helpers.dart';

class _SaveFailingAggregateRepository extends FakeSessionAggregateRepository {
  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> save(
    SessionAggregate aggregate,
  ) async {
    return const Left(NetworkFailure());
  }
}

void main() {
  final upcomingSession = makeSession(
    lifecycleStatus: SessionLifecycleStatus.scheduled,
    startsAt: DateTime.utc(2026, 7, 1, 9),
    endsAt: DateTime.utc(2026, 7, 1, 9, 30),
  );

  FakeSessionAggregateRepository seedScheduledAggregate(
    FakeSessionAggregateRepository repo,
  ) {
    repo.store['booking_1'] = makeAggregate(
      id: 'booking_1',
      status: SessionLifecycleStatus.scheduled,
      startsAt: DateTime.utc(2026, 7, 1, 9),
      paymentReference: null,
      pricingType: SessionPricingType.free,
    );
    return repo;
  }

  group('TeacherDashboardBloc tutor cancel reflection', () {
    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'TeacherSessionCancelled removes session when cancel succeeds',
      build: () {
        final aggregateRepo = seedScheduledAggregate(
          FakeSessionAggregateRepository(),
        );
        return buildTestTeacherDashboardBloc(
          sessionRepo: FakeSessionRepository(),
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: FakeScheduleRepository(),
            bookedSlotLockRepository: FakeBookedSlotLockRepository(),
          ),
          blockGeneratedSlot: BlockGeneratedSlotUseCase(
            FakeScheduleRepository(),
          ),
          availabilityProvider: FakeAvailabilityProvider(),
          cancelSession: buildCancelSessionViaServerUseCase(
            repository: aggregateRepo,
          ),
          completeSession: buildCompleteSessionViaServerUseCase(),
          scheduleRepo: FakeScheduleRepository(),
        );
      },
      seed: () => seedTeacherDashboardSuccess(
        upcomingSessions: [upcomingSession],
      ),
      act: (bloc) => bloc.add(
        const TeacherSessionCancelled(
          bookingId: 'booking_1',
          reason: tutorCancelSessionReason,
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>().having(
          (s) => s.sessionCancelInProgress,
          'in progress',
          'booking_1',
        ),
        isA<TeacherDashboardSuccess>()
            .having((s) => s.upcomingSessions, 'upcoming cleared', isEmpty)
            .having((s) => s.sessionCancelSucceeded, 'success', isTrue),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'TeacherSessionCancelled keeps session when aggregate is missing',
      build: () {
        return buildTestTeacherDashboardBloc(
          sessionRepo: FakeSessionRepository(),
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: FakeScheduleRepository(),
            bookedSlotLockRepository: FakeBookedSlotLockRepository(),
          ),
          blockGeneratedSlot: BlockGeneratedSlotUseCase(
            FakeScheduleRepository(),
          ),
          availabilityProvider: FakeAvailabilityProvider(),
          cancelSession: buildCancelSessionViaServerUseCase(
            repository: FakeSessionAggregateRepository(),
          ),
          completeSession: buildCompleteSessionViaServerUseCase(),
          scheduleRepo: FakeScheduleRepository(),
        );
      },
      seed: () => seedTeacherDashboardSuccess(
        upcomingSessions: [upcomingSession],
      ),
      act: (bloc) => bloc.add(
        const TeacherSessionCancelled(
          bookingId: 'booking_1',
          reason: tutorCancelSessionReason,
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>().having(
          (s) => s.sessionCancelInProgress,
          'in progress',
          'booking_1',
        ),
        isA<TeacherDashboardSuccess>()
            .having(
              (s) => s.sessionCancelFailure,
              'failure',
              isA<NotFoundFailure>(),
            )
            .having((s) => s.upcomingSessions.length, 'still listed', 1),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'TeacherSessionCancelled keeps session when aggregate save fails',
      build: () {
        final aggregateRepo = seedScheduledAggregate(
          _SaveFailingAggregateRepository(),
        );
        return buildTestTeacherDashboardBloc(
          sessionRepo: FakeSessionRepository(),
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: FakeScheduleRepository(),
            bookedSlotLockRepository: FakeBookedSlotLockRepository(),
          ),
          blockGeneratedSlot: BlockGeneratedSlotUseCase(
            FakeScheduleRepository(),
          ),
          availabilityProvider: FakeAvailabilityProvider(),
          cancelSession: buildCancelSessionViaServerUseCase(
            repository: aggregateRepo,
          ),
          completeSession: buildCompleteSessionViaServerUseCase(),
          scheduleRepo: FakeScheduleRepository(),
        );
      },
      seed: () => seedTeacherDashboardSuccess(
        upcomingSessions: [upcomingSession],
      ),
      act: (bloc) => bloc.add(
        const TeacherSessionCancelled(
          bookingId: 'booking_1',
          reason: tutorCancelSessionReason,
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>().having(
          (s) => s.sessionCancelInProgress,
          'in progress',
          'booking_1',
        ),
        isA<TeacherDashboardSuccess>()
            .having(
              (s) => s.sessionCancelFailure,
              'failure',
              isA<NetworkFailure>(),
            )
            .having((s) => s.upcomingSessions.length, 'still listed', 1),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'TeacherSessionCancelled keeps session when bookingId mismatches aggregate id',
      build: () {
        final aggregateRepo = FakeSessionAggregateRepository()
          ..store['session_1'] = makeAggregate(
            id: 'session_1',
            status: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.utc(2026, 7, 1, 9),
            paymentReference: null,
            pricingType: SessionPricingType.free,
          );
        return buildTestTeacherDashboardBloc(
          sessionRepo: FakeSessionRepository(),
          getAvailability: buildGetTeacherAvailabilityUseCase(
            scheduleRepository: FakeScheduleRepository(),
            bookedSlotLockRepository: FakeBookedSlotLockRepository(),
          ),
          blockGeneratedSlot: BlockGeneratedSlotUseCase(
            FakeScheduleRepository(),
          ),
          availabilityProvider: FakeAvailabilityProvider(),
          cancelSession: buildCancelSessionViaServerUseCase(
            repository: aggregateRepo,
          ),
          completeSession: buildCompleteSessionViaServerUseCase(),
          scheduleRepo: FakeScheduleRepository(),
        );
      },
      seed: () => seedTeacherDashboardSuccess(
        upcomingSessions: [
          makeSession(
            id: 'session_1',
            lifecycleStatus: SessionLifecycleStatus.scheduled,
            startsAt: DateTime.utc(2026, 7, 1, 9),
            endsAt: DateTime.utc(2026, 7, 1, 9, 30),
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        const TeacherSessionCancelled(
          bookingId: 'booking_1',
          reason: tutorCancelSessionReason,
        ),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>().having(
          (s) => s.sessionCancelInProgress,
          'in progress',
          'booking_1',
        ),
        isA<TeacherDashboardSuccess>()
            .having(
              (s) => s.sessionCancelFailure,
              'failure',
              isA<NotFoundFailure>(),
            )
            .having((s) => s.upcomingSessions.length, 'still listed', 1),
      ],
    );

    blocTest<TeacherDashboardBloc, TeacherDashboardState>(
      'reload clears stale sessionCancelFailure',
      build: () {
        final scheduleRepo = FakeScheduleRepository()
          ..schedule = makeWeeklySchedule();
        final sessionRepo = FakeSessionRepository()
          ..sessions = [upcomingSession];
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
          scheduleRepo: scheduleRepo,
        );
      },
      seed: () =>
          seedTeacherDashboardSuccess(
            upcomingSessions: [upcomingSession],
          ).copyWith(
            sessionCancelFailure: const InvalidTransitionFailure(
              action: 'cancelByTeacher',
              actorRole: 'teacher',
              reasonCode: 'invalid_transition',
            ),
          ),
      act: (b) => b.add(
        const TeacherDashboardLoadRequested(teacherId: 'teacher_1'),
      ),
      expect: () => [
        isA<TeacherDashboardSuccess>()
            .having((s) => s.isRefreshing, 'refreshing', isTrue)
            .having(
              (s) => s.sessionCancelFailure,
              'cleared on refresh start',
              isNull,
            )
            .having(
              (s) => s.sessionCancelSucceeded,
              'success cleared on refresh start',
              isFalse,
            ),
        anything,
      ],
    );
  });
}
