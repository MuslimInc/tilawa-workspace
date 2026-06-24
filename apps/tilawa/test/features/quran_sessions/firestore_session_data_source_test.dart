import 'package:checks/checks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_session_repository.dart';

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
}
