import 'package:equatable/equatable.dart';

import 'session_participant_role.dart';

/// Canonical call-tracking event types for Quran Sessions.
enum QuranSessionCallTelemetryEventType {
  joinRequested,
  joinSucceeded,
  joinFailed,
  participantConnected,
  participantDisconnected,
  reconnect,
  network,
  leave,
  callEnded,
}

/// Client-originated call telemetry payload (no tokens / recordings).
class QuranSessionCallTelemetryEvent extends Equatable {
  const QuranSessionCallTelemetryEvent({
    required this.eventId,
    required this.sessionId,
    required this.actorId,
    required this.actorRole,
    required this.type,
    required this.clientTimestampMs,
    this.reasonCode,
    this.remoteParticipantId,
    this.networkQuality,
    this.metadata = const {},
  });

  final String eventId;
  final String sessionId;
  final String actorId;
  final SessionParticipantRole actorRole;
  final QuranSessionCallTelemetryEventType type;
  final int clientTimestampMs;
  final String? reasonCode;
  final String? remoteParticipantId;
  final String? networkQuality;
  final Map<String, Object?> metadata;

  @override
  List<Object?> get props => [
    eventId,
    sessionId,
    actorId,
    actorRole,
    type,
    clientTimestampMs,
    reasonCode,
    remoteParticipantId,
    networkQuality,
    metadata,
  ];
}

/// Builds a deterministic idempotency key per actor + session + semantic key.
String buildCallTelemetryEventId({
  required String sessionId,
  required String actorId,
  required String semanticKey,
}) {
  return '${sessionId}_${actorId}_$semanticKey';
}
