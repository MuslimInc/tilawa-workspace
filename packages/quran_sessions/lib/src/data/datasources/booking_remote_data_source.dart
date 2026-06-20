import '../dtos/quran_booking_dto.dart';
import '../dtos/session_review_dto.dart';

abstract interface class BookingRemoteDataSource {
  Future<QuranBookingDto> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  });

  Future<QuranBookingDto> cancelBooking(
    String bookingId, {
    required String reason,
  });

  Future<QuranBookingDto> rescheduleBooking(
    String bookingId, {
    required String newSlotId,
  });

  Future<List<QuranBookingDto>> getStudentBookings(String studentId);

  Future<SessionReviewDto> submitReview({
    required String sessionId,
    required int rating,
    String? comment,
  });
}
