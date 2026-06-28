import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firebase_session_aggregate_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';

void main() {
  group('FirebaseSessionAggregateRepository.getById', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseSessionAggregateRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseSessionAggregateRepository(firestore);
    });

    test('loads booking when route id is booking doc id', () async {
      await firestore
          .collection(FirestoreQuranSessionsPaths.bookings)
          .doc('booking_1')
          .set({
            'studentId': 'student_1',
            'teacherId': 'teacher_1',
            'slotId': 'slot_1',
            'startsAt': Timestamp.fromDate(DateTime.utc(2026, 6, 28, 10)),
            'pricingType': 'free',
            'lifecycleStatus': 'scheduled',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 27)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 6, 27)),
            'sessionId': 'session_1',
          });

      final result = await repository.getById('booking_1');

      result.fold(
        (_) => fail('expected Right'),
        (aggregate) {
          check(aggregate.id).equals('booking_1');
          check(aggregate.sessionId).equals('session_1');
        },
      );
    });

    test('loads session when route id is session doc id', () async {
      await firestore
          .collection(FirestoreQuranSessionsPaths.sessions)
          .doc('session_1')
          .set({
            'studentId': 'student_1',
            'teacherId': 'teacher_1',
            'slotId': 'slot_1',
            'startsAt': Timestamp.fromDate(DateTime.utc(2026, 6, 28, 10)),
            'bookingId': 'booking_1',
            'aggregateId': 'booking_1',
            'pricingType': 'free',
            'lifecycleStatus': 'scheduled',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 27)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 6, 27)),
          });

      final result = await repository.getById('session_1');

      result.fold(
        (_) => fail('expected Right'),
        (aggregate) {
          check(aggregate.id).equals('booking_1');
          check(aggregate.sessionId).equals('session_1');
        },
      );
    });

    test(
      'returns not found when id matches neither booking nor session',
      () async {
        final result = await repository.getById('missing_id');

        result.fold(
          (failure) => check(failure).isA<NotFoundFailure>(),
          (_) => fail('expected Left'),
        );
      },
    );
  });
}
