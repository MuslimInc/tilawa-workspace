import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
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

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(FirestoreQuranSessionsPaths.sessions);

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
      final sessionSnap = await _readExistingDoc(_sessions.doc(id));
      if (sessionSnap != null) {
        return Right(
          mapSessionDocToAggregate(
            sessionSnap.id,
            sessionSnap.data()!,
          ),
        );
      }

      final bookingSnap = await _readExistingDoc(_bookings.doc(id));
      if (bookingSnap != null) {
        return Right(
          mapBookingDocToAggregate(
            bookingSnap.id,
            bookingSnap.data()!,
          ),
        );
      }

      final linkedBooking = await _readLinkedBookingBySessionId(id);
      if (linkedBooking != null) {
        return Right(
          mapBookingDocToAggregate(
            linkedBooking.id,
            linkedBooking.data(),
          ),
        );
      }

      return Left(NotFoundFailure('SessionAggregate($id)'));
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  /// Firestore rules deny reads on non-existent booking docs when the rule
  /// inspects [DocumentSnapshot.data]. Treat that as a miss and keep resolving.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _readExistingDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        return null;
      }
      return snap;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _readLinkedBookingBySessionId(
    String sessionId,
  ) async {
    try {
      final linkedBooking = await _bookings
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();
      if (linkedBooking.docs.isEmpty) {
        return null;
      }
      return linkedBooking.docs.first;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
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
        isEqualTo: _lifecycleToFirestore(status),
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

  String _lifecycleToFirestore(SessionLifecycleStatus status) {
    return status.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
  }

  Map<String, dynamic> _toFirestore(SessionAggregate aggregate) => {
    'bookingId': aggregate.id,
    'aggregateId': aggregate.id,
    'teacherId': aggregate.teacherId,
    'studentId': aggregate.studentId,
    'slotId': aggregate.slotId,
    'startsAt': Timestamp.fromDate(aggregate.startsAt.toUtc()),
    'pricingType': aggregate.pricingType.name,
    'lifecycleStatus': _lifecycleToFirestore(aggregate.lifecycleStatus),
    'rescheduleCount': aggregate.rescheduleCount,
    'cancellationReason': aggregate.cancellationReason,
    'lastActionReason': aggregate.lastActionReason,
    'paymentReference': aggregate.paymentReference,
    'createdAt': Timestamp.fromDate(aggregate.createdAt.toUtc()),
    'updatedAt': Timestamp.fromDate(aggregate.updatedAt.toUtc()),
  };
}
