import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_command_gateway.dart';
import '../gateways/session_notification_gateway.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../policies/configurable_cancellation_policy.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';

class CancelSessionUseCase {
  const CancelSessionUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._cancellationPolicy,
    required this._commandGateway,
    required this._notificationGateway,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final ConfigurableCancellationPolicy _cancellationPolicy;
  final SessionCommandGateway _commandGateway;
  final SessionNotificationGateway _notificationGateway;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String sessionId,
    required ActorRole actorRole,
    required String actorId,
    required String reason,
    ActionSource source = ActionSource.mobileApp,
  }) async {
    final loaded = await _aggregateRepository.getById(sessionId);
    if (loaded.isLeft()) return loaded;
    final aggregate = loaded.fold(
      (_) => throw StateError('unreachable'),
      (r) => r,
    );

    final action = switch (actorRole) {
      ActorRole.student => SessionAction.cancelByStudent,
      ActorRole.teacher => SessionAction.cancelByTeacher,
      ActorRole.admin => SessionAction.cancelByAdmin,
      ActorRole.system => SessionAction.cancelByAdmin,
    };

    final next = _lifecycleGuard.applyTransition(
      currentStatus: aggregate.lifecycleStatus,
      action: action,
      actor: actorRole,
      reason: reason,
      sessionStartsAt: aggregate.startsAt,
    );
    if (next.isLeft()) return next.map((_) => throw StateError('noop'));

    final policy = _cancellationPolicy.evaluate(
      actor: actorRole,
      sessionStartsAt: aggregate.startsAt,
      pricingType: aggregate.pricingType,
    );
    if (policy.isLeft()) return policy.map((_) => throw StateError('noop'));

    // Refunds are admin-approved via approveSessionRefund (manual_pending until
    // payment provider is configured). Cancellation proceeds without auto-refund.

    await _commandGateway.releaseSlot(slotId: aggregate.slotId);

    final updated = aggregate.copyWith(
      lifecycleStatus: next.fold((_) => throw StateError('noop'), (r) => r),
      cancellationReason: reason,
      lastActionReason: reason,
      updatedAt: _now(),
    );
    final saved = await _aggregateRepository.save(updated);
    if (saved.isLeft()) return saved;

    await _auditRepository.append(
      SessionAuditEvent(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        action: action,
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
        kind: SessionNotificationKind.cancellation,
        recipientUserIds: [aggregate.teacherId, aggregate.studentId],
        payload: {'reason': reason},
      ),
    );
    return Right(updated);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
