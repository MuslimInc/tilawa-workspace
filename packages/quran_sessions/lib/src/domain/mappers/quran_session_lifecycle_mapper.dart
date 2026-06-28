import '../entities/quran_session.dart';
import '../entities/session_lifecycle_status.dart';

/// Maps a pending tutor-approval request to a scheduled upcoming session.
///
/// Used after server accept when optimistically updating the teacher dashboard.
QuranSession mapAcceptedBookingToScheduledSession(QuranSession pending) {
  return QuranSession(
    id: pending.id,
    bookingId: pending.bookingId,
    teacherId: pending.teacherId,
    studentId: pending.studentId,
    startsAt: pending.startsAt,
    endsAt: pending.endsAt,
    callType: pending.callType,
    status: QuranSessionStatus.scheduled,
    lifecycleStatus: SessionLifecycleStatus.scheduled,
    bookingType: pending.bookingType,
    callProviderKind: pending.callProviderKind,
    meetingLink: pending.meetingLink,
    callRoomId: pending.callRoomId,
    providerSessionId: pending.providerSessionId,
    joinToken: pending.joinToken,
    participants: pending.participants,
    notes: pending.notes,
  );
}
