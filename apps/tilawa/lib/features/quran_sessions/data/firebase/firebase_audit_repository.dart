import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firebase_session_mutation_gateway.dart';
import 'session_firestore_mapper.dart';

/// Reads audit events from `quran_session_events`; appends are server-only.
class FirebaseAuditRepository implements AuditRepository {
  FirebaseAuditRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('quran_session_events');

  @override
  Future<Either<QuranSessionsFailure, void>> append(
    SessionAuditEvent event,
  ) async {
    // Lifecycle Cloud Functions write audit rows; client append is a no-op.
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionAuditEvent>>> listBySessionId(
    String sessionId,
  ) async {
    try {
      final bySession = await _events
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp')
          .get();
      if (bySession.docs.isNotEmpty) {
        return Right(
          bySession.docs.map((d) => mapEventDocToAuditEvent(d.data())).toList(),
        );
      }
      final byBooking = await _events
          .where('bookingId', isEqualTo: sessionId)
          .orderBy('timestamp')
          .get();
      final byAggregate = await _events
          .where('aggregateId', isEqualTo: sessionId)
          .orderBy('timestamp')
          .get();
      final merged = <String, SessionAuditEvent>{};
      for (final doc in [...byBooking.docs, ...byAggregate.docs]) {
        merged[doc.id] = mapEventDocToAuditEvent(doc.data());
      }
      return Right(
        merged.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }
}
