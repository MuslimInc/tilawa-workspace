import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firebase_session_mutation_gateway.dart';
import 'firestore_exception_mapper.dart';

/// Firestore read model for pending reschedule requests.
class FirebaseRescheduleRequestRepository
    implements RescheduleRequestRepository {
  FirebaseRescheduleRequestRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'quran_reschedule_requests';

  @override
  Future<Either<QuranSessionsFailure, PendingRescheduleRequest?>>
  getPendingByBookingId(String bookingId) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('bookingId', isEqualTo: bookingId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return const Right(null);
      }
      return Right(_mapDoc(snap.docs.first));
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  PendingRescheduleRequest _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final newStartsAt = data['newStartsAt'];
    return PendingRescheduleRequest(
      requestId: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      requestedByUserId: data['requestedByUserId'] as String? ?? '',
      requestedByRole: _parseActorRole(data['requestedByRole'] as String?),
      reason: data['reason'] as String? ?? '',
      newStartsAt:
          readDateTime(newStartsAt)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: data['status'] as String? ?? 'pending',
    );
  }

  ActorRole _parseActorRole(String? raw) => switch (raw) {
    'teacher' => ActorRole.teacher,
    'admin' => ActorRole.admin,
    'system' => ActorRole.system,
    _ => ActorRole.student,
  };
}
