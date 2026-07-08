import 'package:equatable/equatable.dart';

import 'legacy_status_lifecycle_mapper.dart';
import 'session_booking_type.dart';
import 'session_call_provider_kind.dart';
import 'session_call_type.dart';
import 'session_lifecycle_status.dart';
import 'session_participant.dart';

/// The canonical state of a booked/active/completed session.
enum QuranSessionStatus {
  scheduled,
  inProgress,
  completed,
  cancelledByStudent,
  cancelledByTeacher,
  noShow,
}

/// Time-based classification of a session relative to `now`.
///
/// Backend/list queries split sessions by [endsAt] so ongoing sessions
/// (started but not ended) stay in the active list, not in past:
///
///   - `now < startsAt`        → [QuranSessionTimePhase.upcoming]
///   - `startsAt <= now <= endsAt` → [QuranSessionTimePhase.ongoing]
///   - `now > endsAt`         → [QuranSessionTimePhase.past]
enum QuranSessionTimePhase { upcoming, ongoing, past }

/// A Quran tutoring session as returned from the backend.
class QuranSession extends Equatable {
  const QuranSession({
    required this.id,
    required this.bookingId,
    required this.teacherId,
    required this.studentId,
    required this.startsAt,
    required this.endsAt,
    required this.callType,
    required this.status,
    this.lifecycleStatus,
    this.bookingType = SessionBookingType.individual,
    this.callProviderKind = SessionCallProviderKind.external,
    this.meetingLink,
    this.callRoomId,
    this.providerSessionId,
    this.joinToken,
    this.participants = const [],
    this.notes,
    this.paymentReference,
    this.paymentProvider,
    this.paymentStatus,
  });

  final String id;
  final String bookingId;
  final String teacherId;
  final String studentId;
  final DateTime startsAt;
  final DateTime endsAt;
  final SessionCallType callType;
  final QuranSessionStatus status;
  final SessionLifecycleStatus? lifecycleStatus;
  final SessionBookingType bookingType;
  final SessionCallProviderKind callProviderKind;

  /// Populated for [SessionCallType.externalMeeting].
  final String? meetingLink;

  /// Legacy alias — prefer [providerSessionId].
  final String? callRoomId;

  /// Provider channel / room id (server-issued).
  final String? providerSessionId;

  /// Short-lived join token (server-issued only).
  final String? joinToken;

  final List<SessionParticipant> participants;
  final String? notes;
  final String? paymentReference;
  final String? paymentProvider;
  final String? paymentStatus;

  /// External join URL when [callProviderKind] is [SessionCallProviderKind.external].
  String? get joinUrl => meetingLink;

  bool get isManualPayment =>
      paymentProvider == 'manual_off_app' || paymentStatus == 'manual_pending';

  /// Canonical lifecycle status with backwards-compatible fallback.
  SessionLifecycleStatus get effectiveLifecycleStatus =>
      lifecycleStatus ?? status.toLifecycleStatus();

  /// `now` is before [startsAt] — session has not started yet.
  bool get isUpcoming => DateTime.now().isBefore(startsAt);

  /// [startsAt] has arrived but [endsAt] has not — session is live/ongoing.
  bool get isOngoing =>
      !DateTime.now().isBefore(startsAt) && !DateTime.now().isAfter(endsAt);

  /// `now` is at or after [endsAt] — session has ended.
  bool get isPast => DateTime.now().isAfter(endsAt);

  /// Pure classification at a fixed [now] (testable, no side effects).
  QuranSessionTimePhase phaseAt(DateTime now) {
    if (now.isBefore(startsAt)) return QuranSessionTimePhase.upcoming;
    if (!now.isAfter(endsAt)) return QuranSessionTimePhase.ongoing;
    return QuranSessionTimePhase.past;
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    teacherId,
    studentId,
    startsAt,
    endsAt,
    callType,
    status,
    lifecycleStatus,
    bookingType,
    callProviderKind,
    meetingLink,
    callRoomId,
    providerSessionId,
    joinToken,
    participants,
    notes,
    paymentReference,
    paymentProvider,
    paymentStatus,
  ];
}
