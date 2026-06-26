import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';
import 'firestore_performance_wrapper.dart';

class FirestoreSessionDataSource implements SessionRemoteDataSource {
  FirestoreSessionDataSource(this._firestore, [this._perf]);

  final FirebaseFirestore _firestore;
  final PerformanceMonitoringService? _perf;

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
      lifecycleStatus: data['lifecycleStatus'] as String?,
      meetingLink: (data['meetingLink'] ?? data['meeting_link']) as String?,
      callRoomId: (data['providerSessionId'] ?? data['callRoomId']) as String?,
      bookingType: data['bookingType'] as String?,
      callProvider: data['callProvider'] as String?,
      providerSessionId: data['providerSessionId'] as String?,
      joinToken: data['joinToken'] as String?,
      participants: data['participants'],
      notes: data['notes'] as String?,
    );
  }

  @override
  Future<QuranSessionDto> getSessionById(String sessionId) async {
    return _perf.trace('firestore_getSessionById', () async {
      try {
        final doc = await _sessions.doc(sessionId).get();
        if (!doc.exists) {
          throw NotFoundException('QuranSession($sessionId)');
        }
        return _mapDoc(doc);
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  @override
  Future<SessionQueryPage> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = 30,
  }) => _queryStudentSessions(
    studentId: studentId,
    active: true,
    cursor: cursor,
    limit: limit,
  );

  @override
  Future<SessionQueryPage> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = 30,
  }) => _queryStudentSessions(
    studentId: studentId,
    active: false,
    cursor: cursor,
    limit: limit,
  );

  @override
  Future<List<QuranSessionDto>> getTeacherUpcomingSessions(
    String teacherId, {
    int limit = 30,
  }) async {
    return _perf.trace('firestore_getTeacherUpcomingSessions', () async {
      try {
        final now = writeDateTime(DateTime.now().toUtc());
        final snapshot = await _sessions
            .where('teacherId', isEqualTo: teacherId)
            .where('endsAt', isGreaterThanOrEqualTo: now)
            .orderBy('endsAt')
            .limit(limit)
            .get();
        return snapshot.docs.map(_mapDoc).toList();
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  Future<SessionQueryPage> _queryStudentSessions({
    required String studentId,
    required bool active,
    String? cursor,
    required int limit,
  }) async {
    return _perf.trace('firestore_queryStudentSessions', () async {
      try {
        final now = writeDateTime(DateTime.now().toUtc());
        Query<Map<String, dynamic>> query = _sessions.where(
          'studentId',
          isEqualTo: studentId,
        );
        if (active) {
          // Active = upcoming + ongoing: any session whose [endsAt] has not
          // passed yet. Splitting by `endsAt` (not `startsAt`) keeps sessions
          // that already started but have not ended in the active list.
          query = query
              .where('endsAt', isGreaterThanOrEqualTo: now)
              .orderBy('endsAt');
        } else {
          // Past = ended: [endsAt] before now, most recently ended first.
          query = query
              .where('endsAt', isLessThan: now)
              .orderBy('endsAt', descending: true);
        }
        query = query.limit(limit);
        if (cursor != null && cursor.isNotEmpty) {
          final cursorDoc = await _sessions.doc(cursor).get();
          if (cursorDoc.exists) {
            query = query.startAfterDocument(cursorDoc);
          }
        }
        final snapshot = await query.get();
        final sessions = snapshot.docs.map(_mapDoc).toList();
        final nextCursor = snapshot.docs.length == limit
            ? snapshot.docs.last.id
            : null;
        return (sessions: sessions, nextCursor: nextCursor);
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
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
