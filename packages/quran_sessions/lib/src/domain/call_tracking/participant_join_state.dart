import 'package:equatable/equatable.dart';

import '../entities/session_participant_role.dart';
import 'call_participant_status.dart';

/// Immutable snapshot of one participant's join history after a fold.
///
/// Exposed for tests and admin tooling that want per-participant detail without
/// re-deriving it from the raw event log.
class ParticipantJoinState extends Equatable {
  const ParticipantJoinState({
    required this.role,
    required this.hasEverConnected,
    required this.isConnected,
    required this.firstConnectAt,
    required this.lastConnectAt,
    required this.reconnectCount,
    required this.late,
    required this.status,
  });

  /// State for a participant who has produced no events yet.
  factory ParticipantJoinState.initial(SessionParticipantRole role) {
    return ParticipantJoinState(
      role: role,
      hasEverConnected: false,
      isConnected: false,
      firstConnectAt: null,
      lastConnectAt: null,
      reconnectCount: 0,
      late: null,
      status: CallParticipantStatus.notJoined,
    );
  }

  final SessionParticipantRole role;
  final bool hasEverConnected;
  final bool isConnected;
  final DateTime? firstConnectAt;
  final DateTime? lastConnectAt;
  final int reconnectCount;
  final bool? late;
  final CallParticipantStatus status;

  @override
  List<Object?> get props => [
    role,
    hasEverConnected,
    isConnected,
    firstConnectAt,
    lastConnectAt,
    reconnectCount,
    late,
    status,
  ];
}
