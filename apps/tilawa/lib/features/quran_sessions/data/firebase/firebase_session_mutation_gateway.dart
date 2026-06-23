import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';
import 'session_firestore_mapper.dart';

class FirebaseSessionMutationGateway implements SessionMutationGateway {
  FirebaseSessionMutationGateway(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestoreQuranSessionsPaths.bookings);

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(FirestoreQuranSessionsPaths.sessions);

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> createBooking({
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
    try {
      final callable = _functions.httpsCallable('createSessionBooking');
      final response = await callable.call<Map<String, dynamic>>({
        'teacherId': teacherId,
        'slotId': slotId,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'callType': _callTypeToCf(callType),
        'pricingType': _pricingTypeToCf(pricingType),
        'paymentReference': paymentReference,
        'studentNote': studentNote,
        'idempotencyKey':
            '$studentId:$slotId:${startsAt.toUtc().toIso8601String()}',
      });
      final bookingId = response.data['bookingId'] as String? ?? '';
      return _loadAggregate(bookingId);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        return Left(SlotUnavailableFailure(slotId));
      }
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> cancelSession({
    required String bookingId,
    required String reason,
    required ActorRole actorRole,
  }) async {
    try {
      final callable = _functions.httpsCallable('cancelSessionBooking');
      await callable.call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'reason': reason,
        'actorRole': _actorRoleToCf(actorRole),
      });
      return _loadAggregate(bookingId);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        return Left(NotFoundFailure('SessionAggregate($bookingId)'));
      }
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
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
    try {
      final callable = _functions.httpsCallable('requestSessionReschedule');
      final response = await callable.call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'newSlotId': newSlotId,
        'newStartsAt': newStartsAt.toUtc().toIso8601String(),
        'reason': reason,
        'actorRole': _actorRoleToCf(actorRole),
      });
      final requestId = response.data['requestId'] as String? ?? '';
      final aggregate = await _loadAggregate(bookingId);
      return aggregate.map(
        (value) => RescheduleRequestResult(
          requestId: requestId,
          aggregate: value,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        return Left(NotFoundFailure('SessionAggregate($bookingId)'));
      }
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> confirmReschedule({
    required String requestId,
    required bool accept,
    required ActorRole actorRole,
  }) async {
    try {
      final callable = _functions.httpsCallable('confirmSessionReschedule');
      await callable.call<Map<String, dynamic>>({
        'requestId': requestId,
        'accept': accept,
        'actorRole': _actorRoleToCf(actorRole),
      });
      final requestDoc = await _firestore
          .collection('quran_reschedule_requests')
          .doc(requestId)
          .get();
      final bookingId = requestDoc.data()?['bookingId'] as String? ?? '';
      return _loadAggregate(bookingId);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        return const Left(SlotUnavailableFailure('target_slot'));
      }
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> completeSession({
    required String sessionId,
    required ActorRole actorRole,
  }) async {
    try {
      final callable = _functions.httpsCallable('completeSession');
      await callable.call<Map<String, dynamic>>({
        'sessionId': sessionId,
        'actorRole': _actorRoleToCf(actorRole),
      });
      final sessionDoc = await _sessions.doc(sessionId).get();
      final bookingId = sessionDoc.data()?['bookingId'] as String? ?? sessionId;
      return _loadAggregate(bookingId);
    } on FirebaseFunctionsException catch (_) {
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionAggregate>> markNoShow({
    required String sessionId,
    required ActorRole actorRole,
    required String reason,
  }) async {
    final classification = _classificationForActor(actorRole);
    try {
      final callable = _functions.httpsCallable('markSessionNoShow');
      await callable.call<Map<String, dynamic>>({
        'sessionId': sessionId,
        'classification': classification,
        'actorRole': _actorRoleToCf(actorRole),
        'reason': reason,
      });
      final sessionDoc = await _sessions.doc(sessionId).get();
      final bookingId = sessionDoc.data()?['bookingId'] as String? ?? sessionId;
      return _loadAggregate(bookingId);
    } on FirebaseFunctionsException catch (_) {
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionReportResult>>
  reportSessionConcern({
    required SessionReportCategory category,
    required String description,
    String? bookingId,
  }) async {
    try {
      final callable = _functions.httpsCallable('reportSessionConcern');
      final response = await callable.call<Map<String, dynamic>>({
        'category': category.cfValue,
        'description': description,
        'bookingId': ?bookingId,
      });
      final reportId = response.data['reportId'] as String? ?? '';
      if (reportId.isEmpty) {
        return const Left(UnknownFailure());
      }
      return Right(SessionReportResult(reportId: reportId));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        return Left(NotFoundFailure('Booking($bookingId)'));
      }
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        return const Left(UnauthorizedFailure());
      }
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionDisputeResult>>
  openSessionDispute({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('openSessionDispute');
      final response = await callable.call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'reason': reason,
      });
      final disputeId = response.data['disputeId'] as String? ?? '';
      if (disputeId.isEmpty) {
        return const Left(UnknownFailure());
      }
      return Right(SessionDisputeResult(disputeId: disputeId));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        return Left(NotFoundFailure('Booking($bookingId)'));
      }
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        return const Left(UnauthorizedFailure());
      }
      return const Left(UnknownFailure());
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  Future<Either<QuranSessionsFailure, SessionAggregate>> _loadAggregate(
    String bookingId,
  ) async {
    try {
      final snap = await _bookings.doc(bookingId).get();
      if (!snap.exists) {
        return Left(NotFoundFailure('SessionAggregate($bookingId)'));
      }
      return Right(mapBookingDocToAggregate(snap.id, snap.data() ?? const {}));
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  String _callTypeToCf(SessionCallType type) => switch (type) {
    SessionCallType.voiceCall => 'voiceCall',
    SessionCallType.videoCall => 'videoCall',
    SessionCallType.externalMeeting => 'externalMeeting',
  };

  String _pricingTypeToCf(SessionPricingType type) => switch (type) {
    SessionPricingType.free => 'free',
    SessionPricingType.fixedPerSession => 'fixedPerSession',
    SessionPricingType.subscription => 'subscription',
  };

  String _actorRoleToCf(ActorRole role) => switch (role) {
    ActorRole.student => 'student',
    ActorRole.teacher => 'teacher',
    ActorRole.admin => 'admin',
    ActorRole.system => 'system',
  };

  String _classificationForActor(ActorRole role) => switch (role) {
    ActorRole.teacher => 'student_no_show',
    ActorRole.student => 'student_no_show',
    ActorRole.admin => 'teacher_no_show',
    ActorRole.system => 'both_no_show',
  };
}

QuranSessionsFailure mapFirebaseExceptionToFailure(FirebaseException e) {
  try {
    mapFirebaseException(e);
    return const UnknownFailure();
  } on PermissionDeniedException {
    return const UnauthorizedFailure();
  } on NotFoundException catch (ex) {
    return NotFoundFailure(ex.resourceType);
  } on HttpException catch (ex) {
    return ServerFailure(statusCode: ex.statusCode);
  }
}
