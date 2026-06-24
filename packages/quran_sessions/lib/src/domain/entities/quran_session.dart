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

  /// External join URL when [callProviderKind] is [SessionCallProviderKind.external].
  String? get joinUrl => meetingLink;

  /// Canonical lifecycle status with backwards-compatible fallback.
  SessionLifecycleStatus get effectiveLifecycleStatus =>
      lifecycleStatus ?? status.toLifecycleStatus();

  bool get isUpcoming => startsAt.isAfter(DateTime.now());

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
  ];
}
