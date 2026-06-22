import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_audit_event.dart';
import '../entities/session_lifecycle_status.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_notification_gateway.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../policies/no_show_policy.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';

class MarkNoShowUseCase {
  const MarkNoShowUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._noShowPolicy,
    required this._notificationGateway,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final NoShowPolicy _noShowPolicy;
  final SessionNotificationGateway _notificationGateway;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String sessionId,
    required ActorRole actorRole,
    required String actorId,
    required bool teacherJoined,
    required bool studentJoined,
    ActionSource source = ActionSource.backendJob,
  }) async {
    final loaded = await _aggregateRepository.getById(sessionId);
    if (loaded.isLeft()) return loaded;
    final aggregate = loaded.fold(
      (_) => throw StateError('unreachable'),
      (r) => r,
    );

    final targetStatus = _noShowPolicy.classify(
      startsAt: aggregate.startsAt,
      teacherJoined: teacherJoined,
      studentJoined: studentJoined,
    );

    final action = switch (targetStatus) {
      SessionLifecycleStatus.teacherNoShow => SessionAction.markTeacherNoShow,
      SessionLifecycleStatus.studentNoShow => SessionAction.markStudentNoShow,
      SessionLifecycleStatus.bothNoShow => SessionAction.markBothNoShow,
      _ => SessionAction.startSession,
    };
    if (action == SessionAction.startSession) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'no_show',
          detail: 'grace_window_not_elapsed',
        ),
      );
    }

    final next = _lifecycleGuard.applyTransition(
      currentStatus: aggregate.lifecycleStatus,
      action: action,
      actor: actorRole,
    );
    if (next.isLeft()) return next.map((_) => throw StateError('noop'));

    final updated = aggregate.copyWith(
      lifecycleStatus: next.fold((_) => throw StateError('noop'), (r) => r),
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
      ),
    );
    await _notificationGateway.enqueue(
      SessionNotificationCommand(
        sessionId: sessionId,
        kind: SessionNotificationKind.noShowMarked,
        recipientUserIds: [aggregate.teacherId, aggregate.studentId],
      ),
    );
    return Right(updated);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
