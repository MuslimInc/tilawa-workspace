import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreAvailabilityDataSource implements AvailabilityRemoteDataSource {
  FirestoreAvailabilityDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _availability(String teacherId) =>
      _firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availability);

  @override
  Future<List<TeacherAvailabilityDto>> getSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snapshot = await _availability(teacherId)
          .where('startsAt', isGreaterThanOrEqualTo: writeDateTime(from))
          .where('startsAt', isLessThan: writeDateTime(to))
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TeacherAvailabilityDto(
          slotId: doc.id,
          teacherId: teacherId,
          startsAt: readRequiredDateTime(
            data['startsAt'],
          ).toUtc().toIso8601String(),
          endsAt: readRequiredDateTime(
            data['endsAt'],
          ).toUtc().toIso8601String(),
          isBooked: data['isBooked'] as bool? ?? false,
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> publishSlot(TeacherAvailabilityDto slot) async {
    try {
      final now = DateTime.now();
      await _availability(slot.teacherId).doc(slot.slotId).set({
        'teacherId': slot.teacherId,
        'startsAt': writeDateTime(DateTime.parse(slot.startsAt)),
        'endsAt': writeDateTime(DateTime.parse(slot.endsAt)),
        'isBooked': slot.isBooked,
        'status': 'open',
        'createdAt': writeDateTime(now),
        'updatedAt': writeDateTime(now),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> withdrawSlot(String teacherId, String slotId) async {
    try {
      final ref = _availability(teacherId).doc(slotId);
      final doc = await ref.get();
      if (!doc.exists) {
        throw NotFoundException('TeacherAvailability($slotId)');
      }
      final isBooked = doc.data()?['isBooked'] as bool? ?? false;
      if (isBooked) {
        throw const ConflictException(isSlotUnavailable: true);
      }
      await ref.delete();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}
