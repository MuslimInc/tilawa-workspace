import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_lifecycle_status.dart';
import '../entities/session_pricing_type.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_command_gateway.dart';
import '../gateways/session_notification_gateway.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../policies/booking_integrity_validator.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';
import '../entities/session_audit_event.dart';

class CreateSessionBookingUseCase {
  const CreateSessionBookingUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._bookingIntegrityValidator,
    required this._commandGateway,
    required this._notificationGateway,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final BookingIntegrityValidator _bookingIntegrityValidator;
  final SessionCommandGateway _commandGateway;
  final SessionNotificationGateway _notificationGateway;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String sessionId,
    required String teacherId,
    required String studentId,
    required String slotId,
    required DateTime startsAt,
    required SessionPricingType pricingType,
    required BookingIntegritySnapshot integritySnapshot,
    String? paymentReference,
  }) async {
    final integrity = _bookingIntegrityValidator.validate(integritySnapshot);
    if (integrity.isLeft()) {
      return integrity.map((_) => throw StateError('noop'));
    }

    final createdAt = _now();
    final draft = SessionAggregate(
      id: sessionId,
      teacherId: teacherId,
      studentId: studentId,
      slotId: slotId,
      startsAt: startsAt,
      pricingType: pricingType,
      lifecycleStatus: SessionLifecycleStatus.draft,
      createdAt: createdAt,
      updatedAt: createdAt,
      paymentReference: paymentReference,
    );
    final created = await _aggregateRepository.create(draft);
    if (created.isLeft()) return created;
    final aggregate = created.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );

    if (pricingType == SessionPricingType.fixedPerSession) {
      final pending = _lifecycleGuard.applyTransition(
        currentStatus: aggregate.lifecycleStatus,
        action: SessionAction.initiatePayment,
        actor: ActorRole.student,
      );
      if (pending.isLeft()) return pending.map((_) => throw StateError('noop'));
      final hold = await _commandGateway.holdSlotSoft(
        slotId: slotId,
        ttl: const Duration(minutes: 10),
      );
      if (hold.isLeft()) return hold.map((_) => throw StateError('noop'));
      final capture = await _commandGateway.capturePayment(
        sessionId: sessionId,
        paymentReference: paymentReference ?? 'missing_payment_reference',
      );
      if (capture.isLeft()) return capture.map((_) => throw StateError('noop'));
      final scheduled = _lifecycleGuard.applyTransition(
        currentStatus: pending.fold((l) => throw StateError('noop'), (r) => r),
        action: SessionAction.confirmBooking,
        actor: ActorRole.system,
      );
      if (scheduled.isLeft()) {
        return scheduled.map((_) => throw StateError('noop'));
      }
      final saved = await _aggregateRepository.save(
        aggregate.copyWith(
          lifecycleStatus: scheduled.fold(
            (l) => throw StateError('noop'),
            (r) => r,
          ),
          updatedAt: _now(),
        ),
      );
      if (saved.isLeft()) return saved;
      await _commandGateway.lockSlotHard(slotId: slotId);
      await _notificationGateway.enqueue(
        SessionNotificationCommand(
          sessionId: sessionId,
          kind: SessionNotificationKind.bookingConfirmed,
          recipientUserIds: [teacherId, studentId],
        ),
      );
      final result = saved.fold((l) => throw StateError('noop'), (r) => r);
      await _appendAudit(
        sessionId: sessionId,
        actorId: studentId,
        action: SessionAction.confirmBooking,
        previous: SessionLifecycleStatus.pendingPayment,
        next: result.lifecycleStatus,
      );
      return Right(result);
    }

    final scheduled = _lifecycleGuard.applyTransition(
      currentStatus: aggregate.lifecycleStatus,
      action: SessionAction.confirmFreeBooking,
      actor: ActorRole.student,
    );
    if (scheduled.isLeft()) {
      return scheduled.map((_) => throw StateError('noop'));
    }
    await _commandGateway.lockSlotHard(slotId: slotId);
    final saved = await _aggregateRepository.save(
      aggregate.copyWith(
        lifecycleStatus: scheduled.fold(
          (l) => throw StateError('noop'),
          (r) => r,
        ),
        updatedAt: _now(),
      ),
    );
    if (saved.isLeft()) return saved;
    await _notificationGateway.enqueue(
      SessionNotificationCommand(
        sessionId: sessionId,
        kind: SessionNotificationKind.bookingConfirmed,
        recipientUserIds: [teacherId, studentId],
      ),
    );
    final result = saved.fold((l) => throw StateError('noop'), (r) => r);
    await _appendAudit(
      sessionId: sessionId,
      actorId: studentId,
      action: SessionAction.confirmFreeBooking,
      previous: SessionLifecycleStatus.draft,
      next: result.lifecycleStatus,
    );
    return Right(result);
  }

  Future<void> _appendAudit({
    required String sessionId,
    required String actorId,
    required SessionAction action,
    required SessionLifecycleStatus previous,
    required SessionLifecycleStatus next,
  }) async {
    await _auditRepository.append(
      SessionAuditEvent(
        sessionId: sessionId,
        actorId: actorId,
        actorRole: ActorRole.student,
        action: action,
        source: ActionSource.mobileApp,
        previousStatus: previous,
        newStatus: next,
        createdAt: _now(),
      ),
    );
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
