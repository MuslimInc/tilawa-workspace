import 'package:equatable/equatable.dart';

import 'session_participant_role.dart';

/// Why a remote participant left the RTC channel.
enum SessionCallParticipantDisconnectReason {
  quit,
  dropped,
  unknown,
}

/// Coarse network quality bucket for throttled telemetry.
enum SessionCallNetworkQualityLevel {
  good,
  poor,
  unknown,
}

/// Provider-agnostic in-call events (no Agora/WebRTC types).
sealed class SessionCallProviderEvent extends Equatable {
  const SessionCallProviderEvent({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Local client successfully joined the RTC channel.
final class SessionCallLocalChannelJoined extends SessionCallProviderEvent {
  const SessionCallLocalChannelJoined({required super.sessionId});
}

/// Remote participant appeared in the channel.
final class SessionCallParticipantConnected extends SessionCallProviderEvent {
  const SessionCallParticipantConnected({
    required super.sessionId,
    required this.remoteParticipantId,
    this.remoteRole,
  });

  final String remoteParticipantId;
  final SessionParticipantRole? remoteRole;

  @override
  List<Object?> get props => [sessionId, remoteParticipantId, remoteRole];
}

/// Remote participant left the channel.
final class SessionCallParticipantDisconnected
    extends SessionCallProviderEvent {
  const SessionCallParticipantDisconnected({
    required super.sessionId,
    required this.remoteParticipantId,
    required this.reason,
  });

  final String remoteParticipantId;
  final SessionCallParticipantDisconnectReason reason;

  @override
  List<Object?> get props => [sessionId, remoteParticipantId, reason];
}

/// RTC stack started reconnecting.
final class SessionCallReconnecting extends SessionCallProviderEvent {
  const SessionCallReconnecting({required super.sessionId});
}

/// RTC stack finished reconnecting.
final class SessionCallReconnected extends SessionCallProviderEvent {
  const SessionCallReconnected({required super.sessionId});
}

/// Network quality changed (coordinator throttles writes).
final class SessionCallNetworkQualityChanged extends SessionCallProviderEvent {
  const SessionCallNetworkQualityChanged({
    required super.sessionId,
    required this.level,
  });

  final SessionCallNetworkQualityLevel level;

  @override
  List<Object?> get props => [sessionId, level];
}
