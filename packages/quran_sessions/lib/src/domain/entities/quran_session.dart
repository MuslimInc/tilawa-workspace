import 'package:equatable/equatable.dart';

import 'legacy_status_lifecycle_mapper.dart';
import 'session_call_type.dart';
import 'session_lifecycle_status.dart';

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
    this.meetingLink,
    this.callRoomId,
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

  /// Populated for [SessionCallType.externalMeeting].
  final String? meetingLink;

  /// Populated for in-app call types (Agora / WebRTC).
  final String? callRoomId;

  final String? notes;

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
    meetingLink,
    callRoomId,
    notes,
  ];
}
