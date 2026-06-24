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
    String id,
  ) async {
    try {
      final merged = <String, SessionAuditEvent>{};
      for (final field in ['bookingId', 'aggregateId', 'sessionId']) {
        await _collectTimelineEvents(
          query: _events.where(field, isEqualTo: id),
          merged: merged,
        );
      }
      final timeline = merged.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return Right(timeline);
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }

  Future<void> _collectTimelineEvents({
    required Query<Map<String, dynamic>> query,
    required Map<String, SessionAuditEvent> merged,
  }) async {
    try {
      final snap = await query.orderBy('timestamp').get();
      for (final doc in snap.docs) {
        merged[doc.id] = mapEventDocToAuditEvent(doc.data());
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }
  }
}
