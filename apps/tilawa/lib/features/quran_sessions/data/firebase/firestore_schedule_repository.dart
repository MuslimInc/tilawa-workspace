import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

/// Firestore-backed [ScheduleRemoteDataSource].
///
/// Stores the recurring availability **rules** — never generated slots:
///   - `quran_teacher_profiles/{teacherId}/availability_config/schedule`
///   - `quran_teacher_profiles/{teacherId}/availability_overrides/{yyyy-MM-dd}`
///
/// Field names are camelCase to match the rest of the Firestore schema; the
/// [WeeklyScheduleDto] snake_case JSON contract is a package-internal concern.
class FirestoreScheduleDataSource implements ScheduleRemoteDataSource {
  FirestoreScheduleDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _scheduleDoc(String teacherId) =>
      _firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availabilityConfig)
          .doc(FirestoreQuranSessionsPaths.scheduleDoc);

  CollectionReference<Map<String, dynamic>> _overrides(String teacherId) =>
      _firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availabilityOverrides);

  @override
  Future<WeeklyScheduleDto?> getSchedule(String teacherId) async {
    try {
      final doc = await _scheduleDoc(teacherId).get();
      if (!doc.exists) return null;
      final data = doc.data() ?? const {};
      return WeeklyScheduleDto(
        teacherId: teacherId,
        timezone: data['timezone'] as String? ?? 'Africa/Cairo',
        slotDurationMinutes: data['slotDurationMinutes'] as int? ?? 30,
        minNoticeMinutes: data['minNoticeMinutes'] as int? ?? 120,
        maxHorizonDays: data['maxHorizonDays'] as int? ?? 30,
        bufferBeforeMinutes: data['bufferBeforeMinutes'] as int? ?? 0,
        bufferAfterMinutes: data['bufferAfterMinutes'] as int? ?? 0,
        weeklyRules: _readRules(data['weeklyRules']),
        version: data['version'] as int? ?? 1,
        updatedAt: readDateTime(data['updatedAt'])?.toUtc().toIso8601String(),
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> saveSchedule(WeeklyScheduleDto schedule) async {
    try {
      await _scheduleDoc(schedule.teacherId).set({
        'teacherId': schedule.teacherId,
        'timezone': schedule.timezone,
        'slotDurationMinutes': schedule.slotDurationMinutes,
        'minNoticeMinutes': schedule.minNoticeMinutes,
        'maxHorizonDays': schedule.maxHorizonDays,
        'bufferBeforeMinutes': schedule.bufferBeforeMinutes,
        'bufferAfterMinutes': schedule.bufferAfterMinutes,
        'weeklyRules': schedule.weeklyRules,
        'version': schedule.version,
        'updatedAt': writeDateTime(DateTime.now()),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<AvailabilityOverrideDto>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _overrides(teacherId);
      if (from != null) {
        query = query.where('date', isGreaterThanOrEqualTo: _dateKey(from));
      }
      if (to != null) {
        query = query.where('date', isLessThan: _dateKey(to));
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AvailabilityOverrideDto(
          date: data['date'] as String? ?? doc.id,
          type: data['type'] as String? ?? 'unavailable',
          intervals: _readIntervals(data['intervals']),
          reason: data['reason'] as String?,
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> saveOverride(
    String teacherId,
    AvailabilityOverrideDto override,
  ) async {
    try {
      await _overrides(teacherId).doc(override.date).set({
        'date': override.date,
        'type': override.type,
        'intervals': override.intervals,
        'reason': override.reason,
        'updatedAt': writeDateTime(DateTime.now()),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<void> removeOverride(String teacherId, String dateKey) async {
    try {
      await _overrides(teacherId).doc(dateKey).delete();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, List<Map<String, String>>> _readRules(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, List<Map<String, String>>>{};
    raw.forEach((key, value) {
      result['$key'] = _readIntervals(value);
    });
    return result;
  }

  List<Map<String, String>> _readIntervals(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (m) => {
            'start': m['start'] as String? ?? '00:00',
            'end': m['end'] as String? ?? '00:00',
          },
        )
        .toList();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
