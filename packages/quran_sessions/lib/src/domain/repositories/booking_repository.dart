import 'package:dartz_plus/dartz_plus.dart';

import '../entities/quran_booking.dart';
import '../entities/session_review.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class BookingRepository {
  /// Initiates a booking for a slot. Returns the created [QuranBooking].
  ///
  /// The [paymentReference] is opaque — the app layer resolves payment
  /// via [PaymentProvider] and passes the reference here.
  Future<Either<QuranSessionsFailure, QuranBooking>> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  });

  Future<Either<QuranSessionsFailure, QuranBooking>> cancelBooking(
    String bookingId, {
    required String reason,
  });

  Future<Either<QuranSessionsFailure, QuranBooking>> rescheduleBooking(
    String bookingId, {
    required String newSlotId,
  });

  Future<Either<QuranSessionsFailure, List<QuranBooking>>> getStudentBookings(
    String studentId,
  );

  Future<Either<QuranSessionsFailure, SessionReview>> submitReview({
    required String sessionId,
    required int rating,
    String? comment,
  });
}
