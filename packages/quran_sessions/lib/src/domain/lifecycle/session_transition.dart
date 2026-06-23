import 'package:equatable/equatable.dart';

import '../entities/session_lifecycle_status.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';
import 'transition_side_effect.dart';

/// Immutable lifecycle transition rule.
class SessionTransition extends Equatable {
  const SessionTransition({
    required this.action,
    required this.from,
    required this.to,
    required this.allowedActors,
    required this.requiresReason,
    this.sideEffects = const [],
  });

  final SessionAction action;
  final Set<SessionLifecycleStatus> from;
  final SessionLifecycleStatus to;
  final Set<ActorRole> allowedActors;
  final bool requiresReason;
  final List<TransitionSideEffect> sideEffects;

  bool supportsFrom(SessionLifecycleStatus? status) =>
      status != null && from.contains(status);

  @override
  List<Object?> get props => [
    action,
    from,
    to,
    allowedActors,
    requiresReason,
    sideEffects,
  ];
}
