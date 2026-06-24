import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';

import '../entities/session_participant_role.dart';
import 'call_tracking_failure.dart';

/// Lifecycle transition a participant (or the call as a whole) went through.
///
/// This is the *domain* event vocabulary used by the calculator. It is
/// deliberately smaller than the transport-level
/// `QuranSessionCallTelemetryEventType`: pure connectivity transitions are all
/// the business rules need. Reconnect and interruption are *derived* from the
/// sequence, never reported directly by an untrusted client.
enum CallTrackingEventType {
  /// A participant became connected (first join or a rejoin after a drop).
  joined,

  /// A participant dropped involuntarily (network loss).
  disconnected,

  /// A participant intentionally left the call.
  left,

  /// The call was terminated for everyone.
  callEnded,
}

/// A validated, immutable call-tracking event.
///
/// Construct via [CallTrackingEvent.parse] when the source is untrusted
/// (client payload, Firestore document, provider callback). The public
/// constructor assumes already-validated inputs.
class CallTrackingEvent extends Equatable {
  const CallTrackingEvent({
    required this.eventId,
    required this.role,
    required this.type,
    required this.occurredAt,
  });

  /// Stable idempotency key. Two events with the same [eventId] are treated as
  /// the same event by the calculator (deduped), making client retries safe.
  final String eventId;

  final SessionParticipantRole role;
  final CallTrackingEventType type;
  final DateTime occurredAt;

  int get occurredAtMs => occurredAt.millisecondsSinceEpoch;

  @override
  List<Object?> get props => [eventId, role, type, occurredAt];

  /// Validates an untrusted event payload into a domain event.
  ///
  /// Returns:
  /// - [InvalidParticipantRoleFailure] when [role] is not teacher/student,
  /// - [InvalidEventTypeFailure] when [type] is unknown,
  /// - [MissingTimestampFailure] when [timestampMs] is null or non-positive.
  static Either<CallTrackingFailure, CallTrackingEvent> parse({
    required String? eventId,
    required String role,
    required String type,
    required int? timestampMs,
  }) {
    final parsedRole = _parseRole(role);
    if (parsedRole == null) {
      return Left(InvalidParticipantRoleFailure(role));
    }
    final parsedType = _parseType(type);
    if (parsedType == null) {
      return Left(InvalidEventTypeFailure(type));
    }
    if (timestampMs == null || timestampMs <= 0) {
      return const Left(MissingTimestampFailure());
    }
    return Right(
      CallTrackingEvent(
        eventId: (eventId == null || eventId.trim().isEmpty)
            ? '${role}_${type}_$timestampMs'
            : eventId.trim(),
        role: parsedRole,
        type: parsedType,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      ),
    );
  }

  static SessionParticipantRole? _parseRole(String raw) {
    switch (raw) {
      case 'teacher':
        return SessionParticipantRole.teacher;
      case 'student':
        return SessionParticipantRole.student;
      default:
        return null;
    }
  }

  static CallTrackingEventType? _parseType(String raw) {
    for (final value in CallTrackingEventType.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}
