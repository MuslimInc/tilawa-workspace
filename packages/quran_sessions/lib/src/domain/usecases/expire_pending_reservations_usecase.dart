import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_audit_event.dart';
import '../entities/session_lifecycle_status.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_command_gateway.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../policies/platform_scheduling_policy.dart';
import '../value_objects/session_action.dart';

class ExpirePendingReservationsUseCase {
  const ExpirePendingReservationsUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._commandGateway,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final SessionCommandGateway _commandGateway;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, List<SessionAggregate>>> call() async {
    final pending = await _aggregateRepository.listByStatus(
      SessionLifecycleStatus.pendingPayment,
      startsBefore: _now().subtract(
        PlatformSchedulingPolicy.pendingPaymentSlotHoldTtl,
      ),
    );
    if (pending.isLeft()) return pending;
    final aggregates = pending.fold(
      (_) => <SessionAggregate>[],
      (value) => value,
    );
    final expired = <SessionAggregate>[];

    for (final aggregate in aggregates) {
      final next = _lifecycleGuard.applyTransition(
        currentStatus: aggregate.lifecycleStatus,
        action: SessionAction.expireReservation,
        actor: ActorRole.system,
      );
      if (next.isLeft()) continue;

      if (aggregate.paymentReference != null) {
        await _commandGateway.voidPayment(
          sessionId: aggregate.id,
          paymentReference: aggregate.paymentReference!,
        );
      }
      await _commandGateway.releaseSlot(slotId: aggregate.slotId);
      final updated = aggregate.copyWith(
        lifecycleStatus: next.fold((_) => throw StateError('noop'), (r) => r),
        updatedAt: _now(),
      );
      final save = await _aggregateRepository.save(updated);
      if (save.isRight()) {
        expired.add(updated);
        await _auditRepository.append(
          SessionAuditEvent(
            sessionId: aggregate.id,
            actorId: 'system',
            actorRole: ActorRole.system,
            action: SessionAction.expireReservation,
            source: ActionSource.backendJob,
            previousStatus: aggregate.lifecycleStatus,
            newStatus: updated.lifecycleStatus,
            createdAt: _now(),
          ),
        );
      }
    }
    return Right(expired);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
