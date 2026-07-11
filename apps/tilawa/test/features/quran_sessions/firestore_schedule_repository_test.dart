import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_schedule_repository.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';
import 'package:tilawa_core/services/performance_trace.dart';

void main() {
  group('FirestoreScheduleDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FakePerformanceMonitoringService perf;
    late FirestoreScheduleDataSource dataSource;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      perf = FakePerformanceMonitoringService();
      dataSource = FirestoreScheduleDataSource(firestore, perf);

      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc('teacher_1')
          .collection(FirestoreQuranSessionsPaths.availabilityConfig)
          .doc(FirestoreQuranSessionsPaths.scheduleDoc)
          .set({
            'timezone': 'Africa/Cairo',
            'slotDurationMinutes': 30,
            'minNoticeMinutes': 120,
            'maxHorizonDays': 30,
            'bufferBeforeMinutes': 0,
            'bufferAfterMinutes': 0,
            'weeklyRules': <String, dynamic>{},
            'version': 1,
            'updatedAt': Timestamp.fromDate(DateTime.utc(2024, 1, 1)),
          });
    });

    test('getSchedule reads the schedule document', () async {
      final s1 = await dataSource.getSchedule('teacher_1');
      final s2 = await dataSource.getSchedule('teacher_1');

      check(s1).isNotNull();
      check(s2).isNotNull();
      check(s1!.teacherId).equals(s2!.teacherId);
      check(perf.traceCounts['firestore_getSchedule']).equals(2);
    });

    test('saveSchedule persists updated schedule fields', () async {
      final s1 = await dataSource.getSchedule('teacher_1');
      check(s1).isNotNull();
      check(perf.traceCounts['firestore_getSchedule']).equals(1);

      await dataSource.saveSchedule(
        const WeeklyScheduleDto(
          teacherId: 'teacher_1',
          timezone: 'Africa/Cairo',
          slotDurationMinutes: 45,
          minNoticeMinutes: 120,
          maxHorizonDays: 30,
          bufferBeforeMinutes: 0,
          bufferAfterMinutes: 0,
          weeklyRules: {},
          version: 2,
        ),
      );

      final s2 = await dataSource.getSchedule('teacher_1');
      check(s2).isNotNull();
      check(s2!.slotDurationMinutes).equals(45);
      check(perf.traceCounts['firestore_getSchedule']).equals(2);
    });
  });
}

class FakePerformanceMonitoringService implements PerformanceMonitoringService {
  final Map<String, int> traceCounts = {};

  @override
  Future<T> traceOperation<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    traceCounts[name] = (traceCounts[name] ?? 0) + 1;
    return operation();
  }

  @override
  PerformanceTrace? startTrace(String name) => null;

  @override
  void setEnabled(bool enabled) {}
}
