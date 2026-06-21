import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';

void main() {
  late FakeScheduleRepository scheduleRepo;
  late FakeSessionRepository sessionRepo;
  late FakeBookingRepository bookingRepo;
  late GetTeacherAvailabilityUseCase getAvailability;
  late CreateBookingUseCase createBooking;

  final fixedNow = DateTime.utc(2026, 1, 9);
  TeacherAvailability? generatedSlot;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    sessionRepo = FakeSessionRepository();
    bookingRepo = FakeBookingRepository();
    getAvailability = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      sessionRepository: sessionRepo,
      now: () => fixedNow,
    );
    createBooking = CreateBookingUseCase(bookingRepo, getAvailability);

    final slots = await getAvailability(
      'teacher_1',
      from: DateTime.utc(2026, 1, 10),
      to: DateTime.utc(2026, 1, 17),
    );
    generatedSlot = slots.fold((_) => null, (value) => value.first);
  });

  group('CreateBookingUseCase', () {
    test('books a generated slot that is still available', () async {
      final slot = generatedSlot!;

      final result = await createBooking(
        teacherId: 'teacher_1',
        slotId: slot.slotId,
        requestedCallTypeId: 'externalMeeting',
      );

      check(result.isRight()).isTrue();
      check(bookingRepo.bookings.single.slotId).equals(slot.slotId);
    });

    test('rejects legacy slot ids that are not generated', () async {
      final result = await createBooking(
        teacherId: 'teacher_1',
        slotId: 'slot_1',
        requestedCallTypeId: 'externalMeeting',
      );

      check(result.isLeft()).isTrue();
      result.fold(
        (failure) => check(failure).isA<SlotUnavailableFailure>(),
        (_) => fail('expected Left'),
      );
      check(bookingRepo.bookings).isEmpty();
    });

    test(
      'rejects slot when a session already occupies the start time',
      () async {
        final slot = generatedSlot!;
        sessionRepo.sessions = [
          QuranSession(
            id: 'session_1',
            bookingId: 'booking_existing',
            teacherId: 'teacher_1',
            studentId: 'student_2',
            startsAt: slot.startsAt,
            endsAt: slot.endsAt,
            callType: SessionCallType.externalMeeting,
            status: QuranSessionStatus.scheduled,
          ),
        ];

        final result = await createBooking(
          teacherId: 'teacher_1',
          slotId: slot.slotId,
          requestedCallTypeId: 'externalMeeting',
        );

        check(result.isLeft()).isTrue();
        check(bookingRepo.bookings).isEmpty();
      },
    );
  });
}
