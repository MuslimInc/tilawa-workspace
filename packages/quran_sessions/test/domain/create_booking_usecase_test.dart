import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/src/domain/entities/quran_booking.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/create_booking_usecase.dart';
import '../helpers/fakes/fake_booking_repository.dart';

void main() {
  late FakeBookingRepository repo;
  late CreateBookingUseCase useCase;

  setUp(() {
    repo = FakeBookingRepository();
    useCase = CreateBookingUseCase(repo);
  });

  group('CreateBookingUseCase', () {
    test('creates and returns a confirmed booking', () async {
      final result = await useCase(
        teacherId: 'teacher_1',
        slotId: 'slot_1',
        requestedCallTypeId: 'external_meeting',
      );

      result.fold(
        (f) => fail('expected Right, got $f'),
        (booking) {
          check(booking.teacherId).equals('teacher_1');
          check(booking.status).equals(BookingStatus.confirmed);
        },
      );
      check(repo.bookings).length.equals(1);
    });

    test('returns failure when repository fails', () async {
      repo.failWith = const ServerFailure(statusCode: 500);

      final result = await useCase(
        teacherId: 'teacher_1',
        slotId: 'slot_1',
        requestedCallTypeId: 'external_meeting',
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
