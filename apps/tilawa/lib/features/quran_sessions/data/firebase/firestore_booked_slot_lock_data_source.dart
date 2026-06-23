import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

/// Reads `quran_slot_locks` for student-facing availability (no session PII).
class FirestoreBookedSlotLockDataSource
    implements BookedSlotLockRemoteDataSource {
  FirestoreBookedSlotLockDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _locks =>
      _firestore.collection(FirestoreQuranSessionsPaths.slotLocks);

  @override
  Future<List<SlotLockDto>> getLocksForTeacher(String teacherProfileId) async {
    try {
      final snapshot = await _locks
          .where('teacherId', isEqualTo: teacherProfileId)
          .get();
      return snapshot.docs.map(_mapDoc).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  SlotLockDto _mapDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SlotLockDto(
      slotId: data['slotId'] as String? ?? doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      lockType: data['lockType'] as String? ?? 'hard',
      expiresAt: readDateTime(data['expiresAt']),
    );
  }
}
