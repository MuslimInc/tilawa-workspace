import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreSessionDataSource implements SessionRemoteDataSource {
  FirestoreSessionDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(FirestoreQuranSessionsPaths.sessions);

  QuranSessionDto _mapDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return QuranSessionDto(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      startsAt: readRequiredDateTime(
        data['startsAt'],
      ).toUtc().toIso8601String(),
      endsAt: readRequiredDateTime(data['endsAt']).toUtc().toIso8601String(),
      callType: _mapCallType(data['callType'] as String?),
      status: _mapSessionStatus(data['status'] as String?),
      meetingLink: (data['meetingLink'] ?? data['meeting_link']) as String?,
      callRoomId: data['callRoomId'] as String?,
      notes: data['notes'] as String?,
    );
  }

  @override
  Future<QuranSessionDto> getSessionById(String sessionId) async {
    try {
      final doc = await _sessions.doc(sessionId).get();
      if (!doc.exists) {
        throw NotFoundException('QuranSession($sessionId)');
      }
      return _mapDoc(doc);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<QuranSessionDto>> getStudentSessions(String studentId) async {
    try {
      final snapshot = await _sessions
          .where('studentId', isEqualTo: studentId)
          .orderBy('startsAt', descending: true)
          .get();
      return snapshot.docs.map(_mapDoc).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<QuranSessionDto>> getTeacherSessions(String teacherId) async {
    try {
      final snapshot = await _sessions
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('startsAt', descending: true)
          .get();
      return snapshot.docs.map(_mapDoc).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<QuranSessionDto> updateNotes(
    String sessionId, {
    required String notes,
  }) async {
    try {
      await _sessions.doc(sessionId).set({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return getSessionById(sessionId);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  String _mapCallType(String? raw) => switch (raw) {
    'voiceCall' => 'voice_call',
    'videoCall' => 'video_call',
    _ => 'external_meeting',
  };

  String _mapSessionStatus(String? raw) => switch (raw) {
    'inProgress' => 'in_progress',
    'cancelledByStudent' => 'cancelled_by_student',
    'cancelledByTeacher' => 'cancelled_by_teacher',
    'noShow' => 'no_show',
    _ => raw ?? 'scheduled',
  };
}
