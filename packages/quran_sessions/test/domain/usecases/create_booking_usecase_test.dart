import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_booking_repository.dart';

void main() {
  late FakeScheduleRepository scheduleRepo;
  late FakeBookedSlotLockRepository bookedSlotLockRepo;
  late FakeBookingRepository bookingRepo;
  late GetTeacherAvailabilityUseCase getAvailability;
  late CreateBookingUseCase createBooking;

  final fixedNow = DateTime.utc(2026, 1, 9);
  TeacherAvailability? generatedSlot;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    bookedSlotLockRepo = FakeBookedSlotLockRepository();
    bookingRepo = FakeBookingRepository();
    getAvailability = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      bookedSlotLockRepository: bookedSlotLockRepo,
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
        bookedSlotLockRepo.seedHardLock(
          teacherId: 'teacher_1',
          startUtc: slot.startsAt.toUtc(),
        );

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
