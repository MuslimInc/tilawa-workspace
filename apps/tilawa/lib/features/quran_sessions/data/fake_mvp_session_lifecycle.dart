import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// In-memory lifecycle stack for MVP / widget tests.
class FakeMvpSessionLifecycleStack {
  FakeMvpSessionLifecycleStack._();

  static FakeMvpSessionLifecycleStack? _instance;
  static FakeMvpSessionLifecycleStack get instance =>
      _instance ??= FakeMvpSessionLifecycleStack._();

  final aggregates = <String, SessionAggregate>{};
  final auditEvents = <SessionAuditEvent>[];
  final notifications = <SessionNotificationCommand>[];
  final rescheduleRequests = <String, RescheduleRequestResult>{};

  SessionAggregateRepository get aggregateRepository =>
      _FakeAggregateRepository(this);

  AuditRepository get auditRepository => _FakeAuditRepository(this);

  SessionNotificationGateway get notificationGateway =>
      _FakeNotificationGateway(this);

  SessionCommandGateway get commandGateway => _FakeCommandGateway(this);

  SessionMutationGateway get mutationGateway => _FakeMutationGateway(this);
}

class _FakeAggregateRepository implements SessionAggregateRepository {
  _FakeAggregateRepository(this._stack);
  final FakeMvpSessionLifecycleStack _stack;

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> create(
    SessionAggregate aggregate,
  ) async {
    _stack.aggregates[aggregate.id] = aggregate;
    return Right(aggregate);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> getById(
    String id,
  ) async {
    final value = _stack.aggregates[id];
    if (value == null) return Left(NotFoundFailure('SessionAggregate($id)'));
    return Right(value);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> save(
    SessionAggregate aggregate,
  ) async {
    _stack.aggregates[aggregate.id] = aggregate;
    return Right(aggregate);
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionAggregate>>> listByStatus(
    SessionLifecycleStatus status, {
    DateTime? startsBefore,
  }) async {
    return Right(
      _stack.aggregates.values
          .where((a) => a.lifecycleStatus == status)
          .toList(),
    );
  }
}

class _FakeAuditRepository implements AuditRepository {
  _FakeAuditRepository(this._stack);
  final FakeMvpSessionLifecycleStack _stack;

  @override
  Future<Either<QuranSessionsFailure, void>> append(
    SessionAuditEvent event,
  ) async {
    _stack.auditEvents.add(event);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionAuditEvent>>> listBySessionId(
    String sessionId,
  ) async {
    return Right(
      _stack.auditEvents.where((e) => e.sessionId == sessionId).toList(),
    );
  }
}

class _FakeNotificationGateway implements SessionNotificationGateway {
  _FakeNotificationGateway(this._stack);
  final FakeMvpSessionLifecycleStack _stack;

  @override
  Future<Either<QuranSessionsFailure, void>> enqueue(
    SessionNotificationCommand command,
  ) async {
    _stack.notifications.add(command);
    return const Right(null);
  }
}

class _FakeCommandGateway implements SessionCommandGateway {
  _FakeCommandGateway(this._stack);
  final FakeMvpSessionLifecycleStack _stack;

  @override
  Future<Either<QuranSessionsFailure, void>> capturePayment({
    required String sessionId,
    required String paymentReference,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> holdSlotSoft({
    required String slotId,
    required Duration ttl,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> lockSlotHard({
    required String slotId,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> refundPayment({
    required String sessionId,
    required double fraction,
    required String reason,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> releaseSlot({
    required String slotId,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> swapSlot({
    required String oldSlotId,
    required String newSlotId,
  }) async => const Right(null);

  @override
  Future<Either<QuranSessionsFailure, void>> voidPayment({
    required String sessionId,
    required String paymentReference,
  }) async => const Right(null);
}

class _FakeMutationGateway implements SessionMutationGateway {
  _FakeMutationGateway(this._stack);
  final FakeMvpSessionLifecycleStack _stack;

  @override
  Future<Either<QuranSessionsFailure, SessionBookingOutcome>> createBooking({
    required String teacherId,
    required String studentId,
    required String slotId,
    required DateTime startsAt,
    required DateTime endsAt,
    required SessionCallType callType,
    required SessionPricingType pricingType,
    String? paymentReference,
    String? studentNote,
  }) async {
    final id = 'booking_${_stack.aggregates.length + 1}';
    final aggregate = SessionAggregate(
      id: id,
      teacherId: teacherId,
      studentId: studentId,
      slotId: slotId,
      startsAt: startsAt,
      pricingType: pricingType,
      lifecycleStatus: SessionLifecycleStatus.scheduled,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      paymentReference: paymentReference,
    );
    _stack.aggregates[id] = aggregate;
    return Right(SessionBookingOutcome(aggregate: aggregate));
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> cancelSession({
    required String bookingId,
    required String reason,
    required ActorRole actorRole,
  }) async {
    final current = _stack.aggregates[bookingId];
    if (current == null) {
      return Left(NotFoundFailure('SessionAggregate($bookingId)'));
    }
    final status = switch (actorRole) {
      ActorRole.teacher => SessionLifecycleStatus.cancelledByTeacher,
      ActorRole.admin => SessionLifecycleStatus.cancelledByAdmin,
      _ => SessionLifecycleStatus.cancelledByStudent,
    };
    final updated = current.copyWith(
      lifecycleStatus: status,
      cancellationReason: reason,
      updatedAt: DateTime.now().toUtc(),
    );
    _stack.aggregates[bookingId] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, RescheduleRequestResult>>
  requestReschedule({
    required String bookingId,
    required String newSlotId,
    required DateTime newStartsAt,
    required String reason,
    required ActorRole actorRole,
  }) async {
    final current = _stack.aggregates[bookingId];
    if (current == null) {
      return Left(NotFoundFailure('SessionAggregate($bookingId)'));
    }
    final updated = current.copyWith(
      lifecycleStatus: SessionLifecycleStatus.rescheduled,
      rescheduleCount: current.rescheduleCount + 1,
      updatedAt: DateTime.now().toUtc(),
    );
    _stack.aggregates[bookingId] = updated;
    final requestId = 'req_${_stack.rescheduleRequests.length + 1}';
    final result = RescheduleRequestResult(
      requestId: requestId,
      aggregate: updated,
    );
    _stack.rescheduleRequests[requestId] = result;
    return Right(result);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> confirmReschedule({
    required String requestId,
    required bool accept,
    required ActorRole actorRole,
  }) async {
    final request = _stack.rescheduleRequests[requestId];
    if (request == null) {
      return Left(NotFoundFailure('RescheduleRequest($requestId)'));
    }
    if (!accept) return Right(request.aggregate);
    final updated = request.aggregate.copyWith(
      lifecycleStatus: SessionLifecycleStatus.scheduled,
      updatedAt: DateTime.now().toUtc(),
    );
    _stack.aggregates[updated.id] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> completeSession({
    required String sessionId,
    required ActorRole actorRole,
  }) async {
    SessionAggregate? found;
    String? key;
    for (final entry in _stack.aggregates.entries) {
      if (entry.key == sessionId || entry.value.id == sessionId) {
        found = entry.value;
        key = entry.key;
        break;
      }
    }
    if (found == null || key == null) {
      return Left(NotFoundFailure('SessionAggregate($sessionId)'));
    }
    final updated = found.copyWith(
      lifecycleStatus: SessionLifecycleStatus.completed,
      updatedAt: DateTime.now().toUtc(),
    );
    _stack.aggregates[key] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> markNoShow({
    required String sessionId,
    required ActorRole actorRole,
    required String reason,
  }) async {
    SessionAggregate? found;
    String? key;
    for (final entry in _stack.aggregates.entries) {
      if (entry.key == sessionId || entry.value.id == sessionId) {
        found = entry.value;
        key = entry.key;
        break;
      }
    }
    if (found == null || key == null) {
      return Left(NotFoundFailure('SessionAggregate($sessionId)'));
    }
    final updated = found.copyWith(
      lifecycleStatus: SessionLifecycleStatus.studentNoShow,
      updatedAt: DateTime.now().toUtc(),
    );
    _stack.aggregates[key] = updated;
    return Right(updated);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionReportResult>>
  reportSessionConcern({
    required SessionReportCategory category,
    required String description,
    String? bookingId,
  }) async {
    return const Right(SessionReportResult(reportId: 'report_mvp_1'));
  }

  @override
  Future<Either<QuranSessionsFailure, SessionDisputeResult>>
  openSessionDispute({
    required String bookingId,
    required String reason,
  }) async {
    SessionAggregate? found;
    String? key;
    for (final entry in _stack.aggregates.entries) {
      if (entry.key == bookingId || entry.value.id == bookingId) {
        found = entry.value;
        key = entry.key;
        break;
      }
    }
    if (found == null || key == null) {
      return Left(NotFoundFailure('SessionAggregate($bookingId)'));
    }
    final updated = found.copyWith(
      lifecycleStatus: SessionLifecycleStatus.disputed,
      updatedAt: DateTime.now().toUtc(),
    );
    _stack.aggregates[key] = updated;
    return const Right(SessionDisputeResult(disputeId: 'dispute_mvp_1'));
  }
}
