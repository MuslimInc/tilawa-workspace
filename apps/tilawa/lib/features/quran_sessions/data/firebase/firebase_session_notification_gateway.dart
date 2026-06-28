import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';

/// Enqueues session notifications into the outbox for the delivery worker.
class FirebaseSessionNotificationGateway implements SessionNotificationGateway {
  FirebaseSessionNotificationGateway(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _outbox =>
      _firestore.collection('quran_session_notifications');

  @override
  Future<Either<QuranSessionsFailure, void>> enqueue(
    SessionNotificationCommand command,
  ) async {
    try {
      await _outbox.add({
        'sessionId': command.sessionId,
        'kind': command.kind.name,
        'recipientUserIds': command.recipientUserIds,
        'payload': command.payload,
        'deliveryStatus': {
          'push': 'pending',
          'email': 'pending',
        },
        'retryCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(mapFirebaseExceptionToFailure(e));
    }
  }
}
