import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_booking.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/booking_repository.dart';

class CancelBookingUseCase {
  const CancelBookingUseCase(this._repository);

  final BookingRepository _repository;

  Future<Either<QuranSessionsFailure, QuranBooking>> call(
    String bookingId, {
    required String reason,
  }) => _repository.cancelBooking(bookingId, reason: reason);
}
