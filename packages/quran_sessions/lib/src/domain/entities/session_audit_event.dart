import 'package:equatable/equatable.dart';

import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';
import 'session_lifecycle_status.dart';

/// Immutable audit entry emitted on every lifecycle mutation.
class SessionAuditEvent extends Equatable {
  const SessionAuditEvent({
    required this.sessionId,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.source,
    required this.previousStatus,
    required this.newStatus,
    required this.createdAt,
    this.reason,
  });

  final String sessionId;
  final String actorId;
  final ActorRole actorRole;
  final SessionAction action;
  final ActionSource source;
  final SessionLifecycleStatus previousStatus;
  final SessionLifecycleStatus newStatus;
  final DateTime createdAt;
  final String? reason;

  @override
  List<Object?> get props => [
    sessionId,
    actorId,
    actorRole,
    action,
    source,
    previousStatus,
    newStatus,
    createdAt,
    reason,
  ];
}
