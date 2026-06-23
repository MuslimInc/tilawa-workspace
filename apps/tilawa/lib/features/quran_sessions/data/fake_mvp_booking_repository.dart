import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/quran_sessions_mvp_store.dart';

/// MVP booking repository backed by generated weekly availability.
class FakeMvpBookingRepository implements BookingRepository {
  FakeMvpBookingRepository(this._store, this._authSession);

  final QuranSessionsMvpStore _store;
  final AuthSessionProvider _authSession;

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) async {
    final startUtc = GeneratedSlot.parseStartUtc(
      teacherId: teacherId,
      slotId: slotId,
    );
    if (startUtc == null) {
      return Left(SlotUnavailableFailure(slotId));
    }

    final schedule = _store.schedules[teacherId];
    final durationMinutes = schedule?.slotDuration.minutes ?? 30;
    final endUtc = startUtc.add(Duration(minutes: durationMinutes));

    final hasConflict = _store.sessions.any(
      (session) =>
          session.teacherId == teacherId &&
          _blocksSlot(session.status) &&
          session.startsAt.toUtc() == startUtc,
    );
    if (hasConflict) {
      return Left(SlotUnavailableFailure(slotId));
    }

    final callType = _resolveCallType(requestedCallTypeId);
    final studentId = _authSession.currentUserId ?? 'student_mvp';

    final booking = QuranBooking(
      id: 'booking_${_store.bookings.length + 1}',
      teacherId: teacherId,
      studentId: studentId,
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
      studentId: studentId,
      startsAt: startUtc,
      endsAt: endUtc,
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
    final studentId = _authSession.currentUserId ?? 'student_mvp';
    return Right(
      SessionReview(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        teacherId: 'teacher_1',
        studentId: studentId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
  }

  static bool _blocksSlot(QuranSessionStatus status) => switch (status) {
    QuranSessionStatus.scheduled || QuranSessionStatus.inProgress => true,
    _ => false,
  };

  static SessionCallType _resolveCallType(String id) => switch (id) {
    'voiceCall' => SessionCallType.voiceCall,
    'videoCall' => SessionCallType.videoCall,
    _ => SessionCallType.externalMeeting,
  };
}
