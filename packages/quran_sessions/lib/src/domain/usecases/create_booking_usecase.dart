import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_booking.dart';
import '../repositories/booking_repository.dart';
import '../failures/quran_sessions_failure.dart';

class CreateBookingUseCase {
  const CreateBookingUseCase(this._repository);

  final BookingRepository _repository;

  Future<Either<QuranSessionsFailure, QuranBooking>> call({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) => _repository.createBooking(
    teacherId: teacherId,
    slotId: slotId,
    requestedCallTypeId: requestedCallTypeId,
    paymentReference: paymentReference,
    studentNote: studentNote,
  );
}
