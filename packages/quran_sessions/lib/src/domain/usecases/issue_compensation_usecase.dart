import 'package:dartz_plus/dartz_plus.dart';

import '../entities/compensation_record.dart';
import '../entities/session_aggregate.dart';
import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/compensation_gateway.dart';
import '../gateways/session_notification_gateway.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../policies/configurable_compensation_policy.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';

class IssueCompensationResult {
  const IssueCompensationResult({
    required this.aggregate,
    required this.record,
  });

  final SessionAggregate aggregate;
  final CompensationRecord record;
}

class IssueCompensationUseCase {
  const IssueCompensationUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._compensationPolicy,
    required this._compensationGateway,
    required this._notificationGateway,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final ConfigurableCompensationPolicy _compensationPolicy;
  final CompensationGateway _compensationGateway;
  final SessionNotificationGateway _notificationGateway;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, IssueCompensationResult>> call({
    required String sessionId,
    required ActorRole actorRole,
    required String actorId,
    required String reason,
    bool adminManualRefund = false,
    ActionSource source = ActionSource.adminPanel,
  }) async {
    final loaded = await _aggregateRepository.getById(sessionId);
    if (loaded.isLeft()) return loaded.map((_) => throw StateError('noop'));
    final aggregate = loaded.fold(
      (_) => throw StateError('unreachable'),
      (r) => r,
    );

    final next = _lifecycleGuard.applyTransition(
      currentStatus: aggregate.lifecycleStatus,
      action: SessionAction.issueCompensation,
      actor: actorRole,
      reason: reason,
    );
    if (next.isLeft()) return next.map((_) => throw StateError('noop'));

    final decision = _compensationPolicy.evaluate(
      triggerStatus: aggregate.lifecycleStatus,
      pricingType: aggregate.pricingType,
      adminManualRefund: adminManualRefund,
    );
    final recordEither = await _compensationGateway.execute(
      sessionId: sessionId,
      actions: decision.actions,
      policyRuleId: decision.policyRuleId,
    );
    if (recordEither.isLeft()) {
      return recordEither.map((_) => throw StateError('noop'));
    }

    final updated = aggregate.copyWith(
      lifecycleStatus: next.fold((_) => throw StateError('noop'), (r) => r),
      lastActionReason: reason,
      updatedAt: _now(),
    );
    final saved = await _aggregateRepository.save(updated);
    if (saved.isLeft()) return saved.map((_) => throw StateError('noop'));

    await _auditRepository.append(
      SessionAuditEvent(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: actorRole,
        action: SessionAction.issueCompensation,
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
        kind: SessionNotificationKind.compensationIssued,
        recipientUserIds: [aggregate.studentId],
      ),
    );

    return Right(
      IssueCompensationResult(
        aggregate: updated,
        record: recordEither.fold((_) => throw StateError('noop'), (r) => r),
      ),
    );
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
