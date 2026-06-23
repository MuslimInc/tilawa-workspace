import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_aggregate.dart';
import '../entities/session_audit_event.dart';
import '../failures/quran_sessions_failure.dart';
import '../lifecycle/session_lifecycle_guard.dart';
import '../repositories/audit_repository.dart';
import '../repositories/session_aggregate_repository.dart';
import '../value_objects/action_source.dart';
import '../value_objects/actor_role.dart';
import '../value_objects/session_action.dart';

class CompleteSessionUseCase {
  const CompleteSessionUseCase({
    required this._aggregateRepository,
    required this._lifecycleGuard,
    required this._auditRepository,
    DateTime Function()? now,
  }) : _now = now ?? _nowUtc;

  final SessionAggregateRepository _aggregateRepository;
  final SessionLifecycleGuard _lifecycleGuard;
  final AuditRepository _auditRepository;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, SessionAggregate>> call({
    required String sessionId,
    required ActorRole actorRole,
    required String actorId,
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
      action: SessionAction.completeSession,
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
        action: SessionAction.completeSession,
        source: source,
        previousStatus: aggregate.lifecycleStatus,
        newStatus: updated.lifecycleStatus,
        createdAt: _now(),
      ),
    );
    return Right(updated);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
