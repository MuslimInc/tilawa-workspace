import 'package:dartz_plus/dartz_plus.dart';

import '../entities/generated_slot.dart';
import '../entities/quran_booking.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/booking_repository.dart';
import 'get_teacher_availability_usecase.dart';

/// Creates a booking after verifying the slot is still bookable.
///
/// **Temporary limitation:** slot availability is re-checked client-side by
/// regenerating from the weekly schedule. A Cloud Function or transactional
/// backend validator should enforce schedule rules and prevent double booking
/// before this path is production-hardened.
class CreateBookingUseCase {
  const CreateBookingUseCase(
    this._bookingRepository,
    this._getAvailability,
  );

  final BookingRepository _bookingRepository;
  final GetTeacherAvailabilityUseCase _getAvailability;

  Future<Either<QuranSessionsFailure, QuranBooking>> call({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) async {
    final slotStart = GeneratedSlot.parseStartUtc(
      teacherId: teacherId,
      slotId: slotId,
    );
    if (slotStart == null) {
      return Left(SlotUnavailableFailure(slotId));
    }

    final availabilityResult = await _getAvailability(
      teacherId,
      from: slotStart.subtract(const Duration(hours: 1)),
      to: slotStart.add(const Duration(hours: 2)),
    );
    if (availabilityResult.isLeft()) {
      return availabilityResult.map((_) => throw StateError('unreachable'));
    }
    final slots = availabilityResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );
    final stillAvailable = slots.any(
      (slot) => slot.slotId == slotId && !slot.isBooked,
    );
    if (!stillAvailable) {
      return Left(SlotUnavailableFailure(slotId));
    }

    return _bookingRepository.createBooking(
      teacherId: teacherId,
      slotId: slotId,
      requestedCallTypeId: requestedCallTypeId,
      paymentReference: paymentReference,
      studentNote: studentNote,
    );
  }
}
