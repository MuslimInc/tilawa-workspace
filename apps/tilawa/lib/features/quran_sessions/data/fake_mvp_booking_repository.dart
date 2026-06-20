import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// Fake booking repository that persists bookings in [QuranSessionsMvpStore].
///
/// Creating a booking also creates a [QuranSession] so that [MySessionsScreen]
/// shows the booking immediately.
class FakeMvpBookingRepository implements BookingRepository {
  FakeMvpBookingRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) async {
    // Mark the slot as booked.
    final slotIdx = _store.slots.indexWhere((s) => s.slotId == slotId);
    if (slotIdx == -1) return const Left(SlotUnavailableFailure('unknown'));
    final slot = _store.slots[slotIdx];
    if (slot.isBooked) return Left(SlotUnavailableFailure(slotId));

    // Replace with booked version.
    _store.slots[slotIdx] = TeacherAvailability(
      slotId: slot.slotId,
      teacherId: slot.teacherId,
      startsAt: slot.startsAt,
      endsAt: slot.endsAt,
      isBooked: true,
    );

    final callType = _resolveCallType(requestedCallTypeId);

    final booking = QuranBooking(
      id: 'booking_${_store.bookings.length + 1}',
      teacherId: teacherId,
      studentId: 'student_mvp',
      slotId: slotId,
      requestedCallType: callType,
      pricingType: SessionPricingType.free,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
      paymentReference: paymentReference,
      studentNote: studentNote,
    );

    final session = QuranSession(
      id: 'session_${_store.sessions.length + 1}',
      bookingId: booking.id,
      teacherId: teacherId,
      studentId: 'student_mvp',
      startsAt: slot.startsAt,
      endsAt: slot.endsAt,
      callType: callType,
      status: QuranSessionStatus.scheduled,
      meetingLink: 'https://meet.example.com/room/${booking.id}',
    );

    _store.bookings.add(booking);
    _store.sessions.add(session);

    return Right(booking);
  }

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    final idx = _store.bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return const Left(NotFoundFailure('QuranBooking'));

    final old = _store.bookings[idx];
    final updated = QuranBooking(
      id: old.id,
      teacherId: old.teacherId,
      studentId: old.studentId,
      slotId: old.slotId,
      requestedCallType: old.requestedCallType,
      pricingType: old.pricingType,
      status: BookingStatus.cancelled,
      createdAt: old.createdAt,
      amountPaidUsd: old.amountPaidUsd,
      paymentReference: old.paymentReference,
      sessionId: old.sessionId,
      studentNote: old.studentNote,
    );
    _store.bookings[idx] = updated;

    // Remove corresponding session.
    _store.sessions.removeWhere((s) => s.bookingId == bookingId);

    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> rescheduleBooking(
    String bookingId, {
    required String newSlotId,
  }) async {
    final idx = _store.bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return const Left(NotFoundFailure('QuranBooking'));
    return Right(_store.bookings[idx]);
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranBooking>>> getStudentBookings(
    String studentId,
  ) async {
    return Right(
      _store.bookings.where((b) => b.studentId == studentId).toList(),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, SessionReview>> submitReview({
    required String sessionId,
    required int rating,
    String? comment,
  }) async {
    return Right(
      SessionReview(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        teacherId: 'teacher_1',
        studentId: 'student_mvp',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
  }

  static SessionCallType _resolveCallType(String id) => switch (id) {
    'voiceCall' => SessionCallType.voiceCall,
    'videoCall' => SessionCallType.videoCall,
    _ => SessionCallType.externalMeeting,
  };
}
