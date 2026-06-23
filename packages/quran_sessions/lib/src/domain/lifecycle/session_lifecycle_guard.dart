import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_lifecycle_status.dart';
import '../failures/quran_sessions_failure.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';
import 'session_transition.dart';
import 'session_transition_table.dart';

/// Policy knobs for lifecycle guard behavior.
class SessionLifecyclePolicyConfig {
  const SessionLifecyclePolicyConfig({
    this.blockStudentCancellationWithinMinNotice = true,
    this.studentCancellationMinNotice = const Duration(hours: 1),
  });

  final bool blockStudentCancellationWithinMinNotice;
  final Duration studentCancellationMinNotice;
}

/// Pure validator for lifecycle transitions.
class SessionLifecycleGuard {
  const SessionLifecycleGuard({
    this.transitionTable = const SessionTransitionTable(),
    this.config = const SessionLifecyclePolicyConfig(),
    this.now = _nowUtc,
  });

  final SessionTransitionTable transitionTable;
  final SessionLifecyclePolicyConfig config;
  final DateTime Function() now;

  Either<QuranSessionsFailure, SessionTransition> canTransition({
    required SessionLifecycleStatus? currentStatus,
    required SessionAction action,
    required ActorRole actor,
    String? reason,
    DateTime? sessionStartsAt,
    bool isTargetSlotAvailable = true,
    String targetSlotId = 'unknown_slot',
  }) {
    final transitionEither = _resolveTransition(
      currentStatus: currentStatus,
      action: action,
      actor: actor,
    );

    return transitionEither.flatMap((transition) {
      if (transition.requiresReason && _isBlank(reason)) {
        return Left(ReasonRequiredFailure(action: action.name));
      }

      if (action == SessionAction.confirmReschedule && !isTargetSlotAvailable) {
        return Left(SlotUnavailableFailure(targetSlotId));
      }

      if (_isBlockedLateStudentCancellation(
        action: action,
        sessionStartsAt: sessionStartsAt,
      )) {
        return Left(
          InvalidTransitionFailure(
            action: action.name,
            actorRole: actor.name,
            currentStatus: currentStatus?.name,
            reasonCode: 'late_student_cancellation_blocked',
          ),
        );
      }

      return Right(transition);
    });
  }

  Either<QuranSessionsFailure, SessionLifecycleStatus> applyTransition({
    required SessionLifecycleStatus? currentStatus,
    required SessionAction action,
    required ActorRole actor,
    String? reason,
    DateTime? sessionStartsAt,
    bool isTargetSlotAvailable = true,
    String targetSlotId = 'unknown_slot',
  }) {
    return canTransition(
      currentStatus: currentStatus,
      action: action,
      actor: actor,
      reason: reason,
      sessionStartsAt: sessionStartsAt,
      isTargetSlotAvailable: isTargetSlotAvailable,
      targetSlotId: targetSlotId,
    ).map((transition) => transition.to);
  }

  Either<QuranSessionsFailure, SessionTransition> _resolveTransition({
    required SessionLifecycleStatus? currentStatus,
    required SessionAction action,
    required ActorRole actor,
  }) {
    final transitions = transitionTable.forAction(action);
    SessionTransition? transition;
    for (final candidate in transitions) {
      final matchesFrom = currentStatus == null
          ? candidate.from.isEmpty
          : candidate.supportsFrom(currentStatus);
      if (matchesFrom) {
        transition = candidate;
        break;
      }
    }

    if (transition == null) {
      return Left(
        InvalidTransitionFailure(
          action: action.name,
          actorRole: actor.name,
          currentStatus: currentStatus?.name,
        ),
      );
    }

    if (!transition.allowedActors.contains(actor)) {
      return Left(
        UnauthorizedActorFailure(
          action: action.name,
          actorRole: actor.name,
          allowedActorRoles: transition.allowedActors
              .map((role) => role.name)
              .toList(growable: false),
        ),
      );
    }

    return Right(transition);
  }

  bool _isBlockedLateStudentCancellation({
    required SessionAction action,
    required DateTime? sessionStartsAt,
  }) {
    if (action != SessionAction.cancelByStudent ||
        !config.blockStudentCancellationWithinMinNotice ||
        sessionStartsAt == null) {
      return false;
    }

    final remaining = sessionStartsAt.difference(now());
    return remaining < config.studentCancellationMinNotice;
  }
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

DateTime _nowUtc() => DateTime.now().toUtc();
