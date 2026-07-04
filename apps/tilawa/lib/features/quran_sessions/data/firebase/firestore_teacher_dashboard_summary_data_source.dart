import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';
import 'firestore_performance_wrapper.dart';
import 'firestore_quran_sessions_decoders.dart';

/// One-read access to the dashboard read model maintained by the
/// `projectTeacherDashboard` Cloud Functions
/// (`quran_teacher_profiles/{id}/dashboard/summary`).
///
/// Returns `null` for anything unusable — missing doc, unresolved
/// `updatedAt`, malformed sections — so the caller falls back to the legacy
/// multi-fetch path instead of failing the dashboard.
class FirestoreTeacherDashboardSummaryDataSource
    implements TeacherDashboardSummaryRemoteDataSource {
  FirestoreTeacherDashboardSummaryDataSource(this._firestore, [this._perf]);

  final FirebaseFirestore _firestore;
  final PerformanceMonitoringService? _perf;

  DocumentReference<Map<String, dynamic>> _summaryDoc(
    String teacherProfileId,
  ) => _firestore
      .collection(FirestoreQuranSessionsPaths.teacherProfiles)
      .doc(teacherProfileId)
      .collection(FirestoreQuranSessionsPaths.dashboard)
      .doc(FirestoreQuranSessionsPaths.dashboardSummaryDoc);

  @override
  Future<TeacherDashboardSummaryDto?> fetchSummary(
    String teacherProfileId,
  ) async {
    return _perf.trace('firestore_getDashboardSummary', () async {
      try {
        final doc = await _summaryDoc(teacherProfileId).get();
        if (!doc.exists) return null;
        return _decode(teacherProfileId, doc.data() ?? const {});
      } on FirebaseException catch (e) {
        throw mapFirebaseException(e);
      }
    });
  }

  TeacherDashboardSummaryDto? _decode(
    String teacherProfileId,
    Map<String, dynamic> data,
  ) {
    final updatedAt = readDateTime(data['updatedAt']);
    final teacher = data['teacher'];
    final ownerUserId = teacher is Map ? teacher['userId'] as String? : null;
    if (updatedAt == null || ownerUserId == null || ownerUserId.isEmpty) {
      return null;
    }

    final schedulingRaw = data['schedulingConfig'];
    final scheduleRaw = data['weeklySchedule'];

    return TeacherDashboardSummaryDto(
      teacherProfileId: teacherProfileId,
      ownerUserId: ownerUserId,
      displayName: teacher is Map ? teacher['displayName'] as String? : null,
      countryCode: teacher is Map ? teacher['countryCode'] as String? : null,
      schedulingConfig: marketSchedulingConfigDtoFromMap(
        schedulingRaw is Map ? Map<String, dynamic>.from(schedulingRaw) : null,
      ),
      weeklySchedule: scheduleRaw is Map
          ? weeklyScheduleDtoFromDocData(
              teacherProfileId,
              Map<String, dynamic>.from(scheduleRaw),
            )
          : null,
      overrides: _decodeEntries(
        data['overrides'],
        (id, map) => availabilityOverrideDtoFromDocData(id, map),
        idField: 'date',
      ),
      sessions: _decodeEntries(
        data['sessions'],
        quranSessionDtoFromDocData,
        idField: 'id',
      ),
      sessionsTruncated: data['sessionsTruncated'] == true,
      updatedAt: updatedAt.toUtc().toIso8601String(),
    );
  }

  List<T> _decodeEntries<T>(
    Object? raw,
    T Function(String id, Map<String, dynamic> data) decode, {
    required String idField,
  }) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((entry) {
      final map = Map<String, dynamic>.from(entry);
      return decode(map[idField] as String? ?? '', map);
    }).toList();
  }
}
