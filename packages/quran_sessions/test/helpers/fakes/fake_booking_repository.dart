import 'package:dartz_plus/dartz_plus.dart';

import '../../../lib/src/domain/entities/quran_booking.dart';
import '../../../lib/src/domain/entities/session_call_type.dart';
import '../../../lib/src/domain/entities/session_pricing_type.dart';
import '../../../lib/src/domain/entities/session_review.dart';
import '../../../lib/src/domain/repositories/booking_repository.dart';
import '../../../lib/src/domain/failures/quran_sessions_failure.dart';

class FakeBookingRepository implements BookingRepository {
  final List<QuranBooking> bookings = [];
  final List<SessionReview> submittedReviews = [];
  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) async {
    if (failWith != null) return Left(failWith!);
    final booking = QuranBooking(
      id: 'booking_${bookings.length + 1}',
      teacherId: teacherId,
      studentId: 'student_1',
      slotId: slotId,
      requestedCallType: const _CallTypeFromId().resolve(requestedCallTypeId),
      pricingType: SessionPricingType.free,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
      paymentReference: paymentReference,
      studentNote: studentNote,
    );
    bookings.add(booking);
    return Right(booking);
  }

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    if (failWith != null) return Left(failWith!);
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return const Left(NotFoundFailure('QuranBooking'));
    final updated = _copyWith(bookings[idx], BookingStatus.cancelled);
    bookings[idx] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> rescheduleBooking(
    String bookingId, {
    required String newSlotId,
  }) async {
    if (failWith != null) return Left(failWith!);
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return const Left(NotFoundFailure('QuranBooking'));
    return Right(bookings[idx]);
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranBooking>>> getStudentBookings(
    String studentId,
  ) async {
    if (failWith != null) return Left(failWith!);
    return Right(bookings.where((b) => b.studentId == studentId).toList());
  }

  @override
  Future<Either<QuranSessionsFailure, SessionReview>> submitReview({
    required String sessionId,
    required int rating,
    String? comment,
  }) async {
    if (failWith != null) return Left(failWith!);
    final review = SessionReview(
      id: 'review_${submittedReviews.length + 1}',
      sessionId: sessionId,
      teacherId: 'teacher_1',
      studentId: 'student_1',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    submittedReviews.add(review);
    return Right(review);
  }

  QuranBooking _copyWith(QuranBooking b, BookingStatus status) => QuranBooking(
    id: b.id,
    teacherId: b.teacherId,
    studentId: b.studentId,
    slotId: b.slotId,
    requestedCallType: b.requestedCallType,
    pricingType: b.pricingType,
    status: status,
    createdAt: b.createdAt,
    amountPaidUsd: b.amountPaidUsd,
    paymentReference: b.paymentReference,
    sessionId: b.sessionId,
    studentNote: b.studentNote,
  );
}

class _CallTypeFromId {
  const _CallTypeFromId();
  SessionCallType resolve(String id) => switch (id) {
    'voice_call' => SessionCallType.voiceCall,
    'video_call' => SessionCallType.videoCall,
    _ => SessionCallType.externalMeeting,
  };
}
