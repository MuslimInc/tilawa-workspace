import 'package:checks/checks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_session_repository.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';
import 'package:tilawa_core/services/performance_trace.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreSessionDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreSessionDataSource(firestore);
  });

  Future<void> seedSession({
    required String id,
    required String studentId,
    required DateTime startsAt,
  }) async {
    await firestore
        .collection(FirestoreQuranSessionsPaths.sessions)
        .doc(id)
        .set({
          'studentId': studentId,
          'teacherId': 'teacher1',
          'bookingId': 'booking_$id',
          'startsAt': startsAt,
          'endsAt': startsAt.add(const Duration(minutes: 30)),
          'status': 'scheduled',
          'callType': 'videoCall',
        });
  }

  test(
    'getStudentUpcomingSessions returns only future sessions with limit',
    () async {
      final now = DateTime.now();
      await seedSession(
        id: 'upcoming',
        studentId: 'student1',
        startsAt: now.add(const Duration(days: 1)),
      );
      await seedSession(
        id: 'past',
        studentId: 'student1',
        startsAt: now.subtract(const Duration(days: 1)),
      );

      final page = await dataSource.getStudentUpcomingSessions(
        'student1',
        limit: 10,
      );

      check(page.sessions).length.equals(1);
      check(page.sessions.single.id).equals('upcoming');
      check(page.nextCursor).isNull();
    },
  );

  test('getStudentPastSessions caps result count', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      await seedSession(
        id: 'past_$i',
        studentId: 'student1',
        startsAt: now.subtract(Duration(days: i + 1)),
      );
    }

    final first = await dataSource.getStudentPastSessions(
      'student1',
      limit: 2,
    );
    check(first.sessions.length).equals(2);
    check(first.nextCursor).isNotNull();
  });

  group('direct reads', () {
    late FakePerformanceMonitoringService perf;
    late FirestoreSessionDataSource cachedDataSource;

    setUp(() async {
      perf = FakePerformanceMonitoringService();
      cachedDataSource = FirestoreSessionDataSource(firestore, perf);

      await seedSession(
        id: 'session_123',
        studentId: 'student1',
        startsAt: DateTime.now().add(const Duration(days: 1)),
      );
    });

    test('getSessionById reads from Firestore each time', () async {
      final s1 = await cachedDataSource.getSessionById('session_123');
      final s2 = await cachedDataSource.getSessionById('session_123');

      check(s1.id).equals(s2.id);
      check(perf.traceCounts['firestore_getSessionById']).equals(2);
    });

    test('updateNotes persists notes and refetches the session', () async {
      final s1 = await cachedDataSource.getSessionById('session_123');
      check(s1.notes).isNull();
      check(perf.traceCounts['firestore_getSessionById']).equals(1);

      await cachedDataSource.updateNotes('session_123', notes: 'New notes');

      final s2 = await cachedDataSource.getSessionById('session_123');
      check(s2.notes).equals('New notes');
      check(perf.traceCounts['firestore_getSessionById']).equals(3);
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
