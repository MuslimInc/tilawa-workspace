import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/entities/weekly_schedule.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_availability_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/request_session_reschedule_via_server_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/reschedule/reschedule_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/reschedule/reschedule_event.dart';
import 'package:quran_sessions/src/presentation/blocs/reschedule/reschedule_state.dart';

import 'package:quran_sessions/src/domain/gateways/session_mutation_gateway.dart';
import 'package:quran_sessions/src/domain/value_objects/actor_role.dart';

import '../../helpers/fixtures/session_aggregate_fixtures.dart';

class _FakeGetAvailability implements GetTeacherAvailabilityUseCase {
  _FakeGetAvailability(this._slots);

  final List<TeacherAvailability> _slots;
  Either<QuranSessionsFailure, List<TeacherAvailability>>? nextResult;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
    WeeklySchedule? preloadedSchedule,
  }) async {
    if (nextResult != null) return nextResult!;
    return Right(_slots);
  }
}

class _FakeRequestReschedule
    implements RequestSessionRescheduleViaServerUseCase {
  Either<QuranSessionsFailure, RescheduleRequestResult>? result;

  @override
  Future<Either<QuranSessionsFailure, RescheduleRequestResult>> call({
    required String bookingId,
    required String newSlotId,
    required DateTime newStartsAt,
    required String reason,
    required ActorRole actorRole,
  }) async {
    return result ??
        Right(
          RescheduleRequestResult(
            requestId: 'req_1',
            aggregate: makeAggregate(),
          ),
        );
  }
}

void main() {
  final from = DateTime.utc(2026, 2, 1);
  final to = DateTime.utc(2026, 2, 8);
  final openSlot = TeacherAvailability(
    slotId: 'slot_open',
    teacherId: 'teacher_1',
    startsAt: DateTime.utc(2026, 2, 2, 10),
    endsAt: DateTime.utc(2026, 2, 2, 10, 30),
    isBooked: false,
  );
  final bookedSlot = TeacherAvailability(
    slotId: 'slot_booked',
    teacherId: 'teacher_1',
    startsAt: DateTime.utc(2026, 2, 3, 10),
    endsAt: DateTime.utc(2026, 2, 3, 10, 30),
    isBooked: true,
  );

  group('RescheduleBloc', () {
    blocTest<RescheduleBloc, RescheduleState>(
      'loads only unbooked slots for selection',
      build: () => RescheduleBloc(
        getAvailability: _FakeGetAvailability([openSlot, bookedSlot]),
        requestReschedule: _FakeRequestReschedule(),
      ),
      act: (bloc) => bloc.add(
        RescheduleLoadRequested(
          bookingId: 'booking_1',
          teacherId: 'teacher_1',
          from: from,
          to: to,
        ),
      ),
      expect: () => [
        const RescheduleLoading(),
        isA<RescheduleSelecting>(),
      ],
      verify: (bloc) {
        final state = bloc.state as RescheduleSelecting;
        check(state.availableSlots.length).equals(1);
        check(state.availableSlots.first.slotId).equals('slot_open');
        check(state.canSubmit).isFalse();
      },
    );

    blocTest<RescheduleBloc, RescheduleState>(
      'emits failure when availability load fails',
      build: () {
        final getAvailability = _FakeGetAvailability([]);
        getAvailability.nextResult = const Left(NetworkFailure());
        return RescheduleBloc(
          getAvailability: getAvailability,
          requestReschedule: _FakeRequestReschedule(),
        );
      },
      act: (bloc) => bloc.add(
        RescheduleLoadRequested(
          bookingId: 'booking_1',
          teacherId: 'teacher_1',
          from: from,
          to: to,
        ),
      ),
      expect: () => [
        const RescheduleLoading(),
        isA<RescheduleFailure>(),
      ],
    );

    blocTest<RescheduleBloc, RescheduleState>(
      'submits reschedule when slot and reason are valid',
      build: () => RescheduleBloc(
        getAvailability: _FakeGetAvailability([openSlot]),
        requestReschedule: _FakeRequestReschedule(),
      ),
      seed: () => RescheduleSelecting(
        bookingId: 'booking_1',
        teacherId: 'teacher_1',
        availableSlots: [openSlot],
        selectedSlot: openSlot,
        reason: 'Need a later time',
      ),
      act: (bloc) => bloc.add(
        const RescheduleSubmitted(
          bookingId: 'booking_1',
          actorId: 'student_1',
        ),
      ),
      expect: () => [
        const RescheduleSubmitting(),
        isA<RescheduleSuccess>(),
      ],
      verify: (bloc) {
        final state = bloc.state as RescheduleSuccess;
        check(state.requestId).equals('req_1');
      },
    );
  });
}
