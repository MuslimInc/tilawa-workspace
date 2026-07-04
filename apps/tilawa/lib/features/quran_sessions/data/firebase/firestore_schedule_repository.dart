import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';
import 'firestore_performance_wrapper.dart';
import 'firestore_quran_sessions_decoders.dart';

/// Firestore-backed [ScheduleRemoteDataSource].
///
/// Stores the recurring availability **rules** — never generated slots:
///   - `quran_teacher_profiles/{teacherId}/availability_config/schedule`
///   - `quran_teacher_profiles/{teacherId}/availability_overrides/{yyyy-MM-dd}`
///
/// Field names are camelCase to match the rest of the Firestore schema; the
/// [WeeklyScheduleDto] snake_case JSON contract is a package-internal concern.
class FirestoreScheduleDataSource implements ScheduleRemoteDataSource {
  FirestoreScheduleDataSource(
    this._firestore, [
    this._perf,
  ]);

  final FirebaseFirestore _firestore;
  final PerformanceMonitoringService? _perf;

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
    final schedule = await _perf.trace('firestore_getSchedule', () async {
      try {
        final doc = await _scheduleDoc(teacherId).get();
        if (!doc.exists) return null;
        return weeklyScheduleDtoFromDocData(teacherId, doc.data() ?? const {});
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });

    return schedule;
  }

  @override
  Future<void> saveSchedule(WeeklyScheduleDto schedule) async {
    return _perf.trace('firestore_saveSchedule', () async {
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
    });
  }

  @override
  Future<List<AvailabilityOverrideDto>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async {
    return _perf.trace('firestore_getOverrides', () async {
      try {
        Query<Map<String, dynamic>> query = _overrides(teacherId);
        if (from != null) {
          query = query.where('date', isGreaterThanOrEqualTo: _dateKey(from));
        }
        if (to != null) {
          query = query.where('date', isLessThan: _dateKey(to));
        }
        final snapshot = await query.get();
        return snapshot.docs
            .map(
              (doc) => availabilityOverrideDtoFromDocData(doc.id, doc.data()),
            )
            .toList();
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  @override
  Future<AvailabilityOverrideDto?> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async {
    return _perf.trace('firestore_getOverrideByDate', () async {
      try {
        final doc = await _overrides(teacherId).doc(dateKey).get();
        if (!doc.exists) return null;
        return availabilityOverrideDtoFromDocData(
          doc.id,
          doc.data() ?? const {},
        );
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  @override
  Future<void> saveOverride(
    String teacherId,
    AvailabilityOverrideDto override,
  ) async {
    return _perf.trace('firestore_saveOverride', () async {
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
    });
  }

  @override
  Future<void> removeOverride(String teacherId, String dateKey) async {
    return _perf.trace('firestore_removeOverride', () async {
      try {
        await _overrides(teacherId).doc(dateKey).delete();
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
