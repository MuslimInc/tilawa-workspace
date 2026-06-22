import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_command_gateway.dart';
import '../gateways/session_notification_gateway.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';

class ConfirmRescheduleUseCase {
  const ConfirmRescheduleUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._commandGateway,
    required this._notificationGateway,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final SessionCommandGateway _commandGateway;
  final SessionNotificationGateway _notificationGateway;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String sessionId,
    required ActorRole actorRole,
    required String actorId,
    required String reason,
    required String newSlotId,
    required bool isTargetSlotAvailable,
    ActionSource source = ActionSource.mobileApp,
  }) async {
    final loaded = await _aggregateRepository.getById(sessionId);
    if (loaded.isLeft()) return loaded;
    final aggregate = loaded.fold(
      (_) => throw StateError('unreachable'),
      (r) => r,
    );

    final next = _lifecycleGuard.applyTransition(
      currentStatus: aggregate.lifecycleStatus,
      action: SessionAction.confirmReschedule,
      actor: actorRole,
      reason: reason,
      isTargetSlotAvailable: isTargetSlotAvailable,
      targetSlotId: newSlotId,
    );
    if (next.isLeft()) return next.map((_) => throw StateError('noop'));

    final swap = await _commandGateway.swapSlot(
      oldSlotId: aggregate.slotId,
      newSlotId: newSlotId,
    );
    if (swap.isLeft()) return swap.map((_) => throw StateError('noop'));

    final updated = aggregate.copyWith(
      lifecycleStatus: next.fold((_) => throw StateError('noop'), (r) => r),
      updatedAt: _now(),
      lastActionReason: reason,
    );
    final saved = await _aggregateRepository.save(updated);
    if (saved.isLeft()) return saved;

    await _auditRepository.append(
      SessionAuditEvent(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        action: SessionAction.confirmReschedule,
        source: source,
        previousStatus: aggregate.lifecycleStatus,
        newStatus: updated.lifecycleStatus,
        createdAt: _now(),
        reason: reason,
      ),
    );
    await _notificationGateway.enqueue(
      SessionNotificationCommand(
        sessionId: sessionId,
        kind: SessionNotificationKind.rescheduleConfirmed,
        recipientUserIds: [aggregate.teacherId, aggregate.studentId],
      ),
    );
    return Right(updated);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
