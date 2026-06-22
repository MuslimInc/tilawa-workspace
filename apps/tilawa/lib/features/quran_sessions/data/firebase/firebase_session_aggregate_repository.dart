import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firebase_session_mutation_gateway.dart';
import 'firestore_paths.dart';
import 'session_firestore_mapper.dart';

/// Reads session aggregates from Firestore; mutations delegate to
/// [SessionMutationGateway] when [serverOrchestrated] is true.
class FirebaseSessionAggregateRepository implements SessionAggregateRepository {
  FirebaseSessionAggregateRepository(
    this._firestore, {
    this._mutationGateway,
    this.serverOrchestrated = true,
  });

  final FirebaseFirestore _firestore;
  final SessionMutationGateway? _mutationGateway;
  final bool serverOrchestrated;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestoreQuranSessionsPaths.bookings);

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> create(
    SessionAggregate aggregate,
  ) async {
    if (serverOrchestrated && _mutationGateway != null) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'aggregate_repository',
          detail: 'use_mutation_gateway_for_create',
        ),
      );
    }
    try {
      await _bookings.doc(aggregate.id).set(_toFirestore(aggregate));
      return Right(aggregate);
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> getById(
    String id,
  ) async {
    try {
      final snap = await _bookings.doc(id).get();
      if (!snap.exists) {
        return Left(NotFoundFailure('SessionAggregate($id)'));
      }
      return Right(mapBookingDocToAggregate(snap.id, snap.data() ?? const {}));
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> save(
    SessionAggregate aggregate,
  ) async {
    if (serverOrchestrated &&
        _mutationGateway != null &&
        _isCancellation(aggregate.lifecycleStatus)) {
      return _mutationGateway.cancelSession(
        bookingId: aggregate.id,
        reason:
            aggregate.cancellationReason ?? aggregate.lastActionReason ?? '',
        actorRole: _cancelActor(aggregate.lifecycleStatus),
      );
    }

    try {
      await _bookings
          .doc(aggregate.id)
          .set(
            _toFirestore(aggregate),
            SetOptions(merge: true),
          );
      return Right(aggregate);
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionAggregate>>> listByStatus(
    SessionLifecycleStatus status, {
    DateTime? startsBefore,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _bookings.where(
        'lifecycleStatus',
        isEqualTo: status.name,
      );
      if (startsBefore != null) {
        query = query.where(
          'startsAt',
          isLessThanOrEqualTo: Timestamp.fromDate(startsBefore.toUtc()),
        );
      }
      final snap = await query.get();
      return Right(
        snap.docs
            .map((doc) => mapBookingDocToAggregate(doc.id, doc.data()))
            .toList(),
      );
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  bool _isCancellation(SessionLifecycleStatus status) =>
      status == SessionLifecycleStatus.cancelledByStudent ||
      status == SessionLifecycleStatus.cancelledByTeacher ||
      status == SessionLifecycleStatus.cancelledByAdmin;

  ActorRole _cancelActor(SessionLifecycleStatus status) => switch (status) {
    SessionLifecycleStatus.cancelledByTeacher => ActorRole.teacher,
    SessionLifecycleStatus.cancelledByAdmin => ActorRole.admin,
    _ => ActorRole.student,
  };

  Map<String, dynamic> _toFirestore(SessionAggregate aggregate) => {
    'bookingId': aggregate.id,
    'aggregateId': aggregate.id,
    'teacherId': aggregate.teacherId,
    'studentId': aggregate.studentId,
    'slotId': aggregate.slotId,
    'startsAt': Timestamp.fromDate(aggregate.startsAt.toUtc()),
    'pricingType': aggregate.pricingType.name,
    'lifecycleStatus': aggregate.lifecycleStatus.name,
    'rescheduleCount': aggregate.rescheduleCount,
    'cancellationReason': aggregate.cancellationReason,
    'lastActionReason': aggregate.lastActionReason,
    'paymentReference': aggregate.paymentReference,
    'createdAt': Timestamp.fromDate(aggregate.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(aggregate.updatedAt.toUtc()),
  };
}
